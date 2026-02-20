import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ptapp/models/exercise_model.dart';
import 'package:ptapp/models/program_model.dart';
import 'package:ptapp/models/log_model.dart';
import 'package:ptapp/models/user_model.dart';
import 'package:ptapp/models/message_model.dart';
import 'package:ptapp/models/nutrition_log_model.dart';
import 'package:ptapp/models/nutrition_plan_model.dart';
import 'package:ptapp/models/nutrition_checkin_model.dart';

import 'package:ptapp/models/notification_model.dart';
import 'package:ptapp/services/notification_service.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // --- Exercise Library ---
  Future<String> addExercise(Exercise exercise) async {
    if (exercise.id != null) {
      await _db
          .collection('exercises')
          .doc(exercise.id)
          .set(exercise.toMap(), SetOptions(merge: true));
      return exercise.id!;
    } else {
      final docRef = await _db.collection('exercises').add(exercise.toMap());
      return docRef.id;
    }
  }

  Future<void> deleteExercise(String id) async {
    await _db.collection('exercises').doc(id).delete();
  }

  Stream<List<Exercise>> getExercises() {
    return _db
        .collection('exercises')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Exercise.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // --- Client Management ---
  Stream<List<AppUser>> getClients(String coachId) {
    return _db
        .collection('users')
        .where('role', isEqualTo: UserRole.client.index)
        .where('coachId', isEqualTo: coachId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateClientNotes(String clientId, String notes) async {
    await _db.collection('users').doc(clientId).update({'notes': notes});
  }

  Future<void> toggleBlockClient(String clientId, bool block) async {
    await _db.collection('users').doc(clientId).update({'isBlocked': block});
  }

  Future<void> deleteClient(String clientId) async {
    await _db.collection('users').doc(clientId).delete();
  }

  // --- Program Management ---
  Future<String> createProgram(Program program) async {
    DocumentReference ref = await _db
        .collection('programs')
        .add(program.toMap());
    return ref.id;
  }

  Future<void> updateProgram(Program program) async {
    // If it's a dedicated program (createdForClientId set), we check if we should version
    if (program.createdForClientId != null && program.id != null) {
      final doc = await _db.collection('programs').doc(program.id).get();
      if (doc.exists) {
        final oldData = doc.data()!;
        final oldVersion = oldData['version'] ?? 1;

        // Save old version to history
        await _db
            .collection('programs')
            .doc(program.id)
            .collection('versions')
            .doc(oldVersion.toString())
            .set(oldData);

        // Update with new version
        final newProgram = Program(
          id: program.id,
          name: program.name,
          coachId: program.coachId,
          isPublic: program.isPublic,
          isTemplate: program.isTemplate,
          totalWeeks: program.totalWeeks,
          assignedClientId: program.assignedClientId,
          startDate: program.startDate,
          createdForClientId: program.createdForClientId,
          status: program.status,
          version: oldVersion + 1,
          currentWeek: program.currentWeek,
          currentDay: program.currentDay,
        );
        await _db
            .collection('programs')
            .doc(program.id)
            .set(newProgram.toMap(), SetOptions(merge: true));
        return;
      }
    }
    await _db
        .collection('programs')
        .doc(program.id)
        .set(program.toMap(), SetOptions(merge: true));
  }

  Future<void> startProgram(String programId) async {
    await _db.collection('programs').doc(programId).update({
      'status': ProgramStatus.active.index,
      'startDate': Timestamp.now(),
      'currentWeek': 1,
      'currentDay': 1,
    });
  }

  Future<void> createProgramCopy(
    String originalId,
    String newClientId,
    DateTime startDate,
  ) async {
    // 1. Fetch Original
    final originalDoc = await _db.collection('programs').doc(originalId).get();
    if (!originalDoc.exists) return;

    final originalData = originalDoc.data()!;

    final newProgramData = {
      ...originalData,
      'name': '${originalData['name']} (Copy)',
      'isTemplate': false,
      'assignedClientId': newClientId,
      'createdForClientId': newClientId,
      'startDate': Timestamp.fromDate(startDate),
      'isPublic': false,
      'parentProgramId': originalId, // Added link to parent
    };

    final newProgramRef = await _db.collection('programs').add(newProgramData);

    // 3. Copy Sub-collection 'days'
    final daysSnapshot = await _db
        .collection('programs')
        .doc(originalId)
        .collection('days')
        .get();
    final batch = _db.batch();

    for (var doc in daysSnapshot.docs) {
      final newDayRef = newProgramRef.collection('days').doc();
      batch.set(newDayRef, doc.data());
    }

    await batch.commit();

    await sendPushNotification(
      recipientId: newClientId,
      title: 'New Program Assigned',
      body:
          'Your coach has assigned you a new program: ${newProgramData['name'] as String}. Tap to view.',
      data: {'type': 'new_program'},
    );
  }

  Future<void> applyGlobalUpdate(
    Program publicProgram,
    List<WorkoutDay> newDays,
  ) async {
    // 1. Update the public program itself
    await updateProgram(publicProgram);

    // 2. Find all copies and update them
    final copiesSnapshot = await _db
        .collection('programs')
        .where('parentProgramId', isEqualTo: publicProgram.id)
        .get();

    for (var doc in copiesSnapshot.docs) {
      final copyId = doc.id;
      final copyData = doc.data();

      await _db.collection('programs').doc(copyId).update({
        'name': publicProgram.name,
        'totalWeeks': publicProgram.totalWeeks,
      });

      final existingDays = await _db
          .collection('programs')
          .doc(copyId)
          .collection('days')
          .get();
      final batch = _db.batch();
      for (var dayDoc in existingDays.docs) {
        batch.delete(dayDoc.reference);
      }
      for (var day in newDays) {
        final newDayRef = _db
            .collection('programs')
            .doc(copyId)
            .collection('days')
            .doc();
        batch.set(newDayRef, day.toMap());
      }
      await batch.commit();

      // Send Push Notification
      await sendPushNotification(
        recipientId: copyData['assignedClientId'] ?? '',
        title: 'Program Updated',
        body:
            'Your coach has updated ${publicProgram.name}. Check your dashboard for changes.',
        data: {'type': 'program_update'},
      );
    }
  }

  Stream<List<Program>> getProgramTemplates(String coachId) {
    return _db
        .collection('programs')
        .where('coachId', isEqualTo: coachId)
        .where('isTemplate', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Program.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Program>> getCoachPrograms(String coachId) {
    return _db
        .collection('programs')
        .where('coachId', isEqualTo: coachId)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((doc) => Program.fromMap(doc.data(), doc.id)).toList(),
        );
  }

  Stream<List<Program>> getActiveCoachPrograms(String coachId) {
    return _db
        .collection('programs')
        .where('coachId', isEqualTo: coachId)
        .where('status', isEqualTo: ProgramStatus.active.index)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((doc) => Program.fromMap(doc.data(), doc.id)).toList(),
        );
  }

  Stream<List<Program>> getPublicPrograms(String coachId) {
    return _db
        .collection('programs')
        .where('coachId', isEqualTo: coachId)
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Program.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addWorkoutDay(String programId, WorkoutDay day) async {
    await _db
        .collection('programs')
        .doc(programId)
        .collection('days')
        .add(day.toMap());
  }

  Future<void> updateWorkoutDay(String programId, WorkoutDay day) async {
    await _db
        .collection('programs')
        .doc(programId)
        .collection('days')
        .doc(day.id)
        .set(day.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteWorkoutDay(String programId, String dayId) async {
    await _db
        .collection('programs')
        .doc(programId)
        .collection('days')
        .doc(dayId)
        .delete();
  }

  Future<String> claimPublicProgram(
    String publicProgramId,
    String clientId,
  ) async {
    // 1. Fetch the public program
    final publicProgramDoc = await _db
        .collection('programs')
        .doc(publicProgramId)
        .get();
    if (!publicProgramDoc.exists) throw Exception('Public program not found');

    final publicProgram = Program.fromMap(
      publicProgramDoc.data()!,
      publicProgramDoc.id,
    );

    // 2. Create a new personal copy
    final newProgram = Program(
      name: publicProgram.name,
      coachId: publicProgram.coachId,
      assignedClientId: clientId,
      totalWeeks: publicProgram.totalWeeks,
      status: ProgramStatus.active, // Auto-start the claimed program
      isPublic: false, // This is now a private copy
      startDate: DateTime.now(),
      currentWeek: 1,
      currentDay: 1,
      parentProgramId: publicProgramId,
    );

    final newProgramRef = await _db
        .collection('programs')
        .add(newProgram.toMap());

    // 3. Copy workout days (templates)
    final daysSnapshot = await _db
        .collection('programs')
        .doc(publicProgramId)
        .collection('days')
        .get();

    for (var dayDoc in daysSnapshot.docs) {
      final dayData = dayDoc.data();
      // Add the day to the new program
      final newDayRef = await newProgramRef.collection('days').add(dayData);

      // 4. Copy exercise logs (templates/targets) if they exist
      final exerciseLogsSnapshot = await dayDoc.reference
          .collection('exercise_logs')
          .get();
      for (var exerciseDoc in exerciseLogsSnapshot.docs) {
        await newDayRef.collection('exercise_logs').add(exerciseDoc.data());
      }
    }

    await sendPushNotification(
      recipientId: clientId,
      title: 'New Program Assigned',
      body:
          'Your coach has assigned you a new program: ${publicProgram.name}. Tap to view.',
      data: {'type': 'new_program'},
    );
    return newProgramRef.id;
  }

  Future<void> assignProgramToClient(
    String programId,
    String clientId,
    DateTime startDate,
  ) async {
    // This method assigns an EXISTING program instance (re-assigning or claiming ownership)
    // If using templates, users should use createProgramCopy instead to keep the template pure.
    await _db.collection('programs').doc(programId).update({
      'assignedClientId': clientId,
      'startDate': Timestamp.fromDate(startDate),
    });
    final doc = await _db.collection('programs').doc(programId).get();
    final name = doc.data()?['name'] ?? 'New Program';
    await sendPushNotification(
      recipientId: clientId,
      title: 'New Program Assigned',
      body: 'Your coach has assigned you a new program: $name. Tap to view.',
      data: {'type': 'new_program'},
    );
  }

  Stream<List<Program>> getClientPrograms(String clientId) {
    return _db
        .collection('programs')
        .where('assignedClientId', isEqualTo: clientId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Program.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<Program?> getProgramStream(String programId) {
    return _db.collection('programs').doc(programId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Program.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> updateProgramCoachNotes(String programId, String notes) async {
    await _db.collection('programs').doc(programId).update({
      'coachNotes': notes,
      'notesUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProgramCompletely(String programId) async {
    // 1. If this is a parent program, find and delete all child copies first
    final children = await _db
        .collection('programs')
        .where('parentProgramId', isEqualTo: programId)
        .get();
    for (var childDoc in children.docs) {
      await deleteProgramCompletely(childDoc.id);
    }

    final batch = _db.batch();

    // 2. Delete all workout logs associated with this program
    final logsSnapshot = await _db
        .collection('logs')
        .where('programId', isEqualTo: programId)
        .get();
    for (var doc in logsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 3. Delete all days and their subcollections (exercise_logs)
    final daysSnapshot = await _db
        .collection('programs')
        .doc(programId)
        .collection('days')
        .get();
    for (var dayDoc in daysSnapshot.docs) {
      // Delete exercise logs inside the day
      final exLogsSnapshot = await dayDoc.reference
          .collection('exercise_logs')
          .get();
      for (var exLogDoc in exLogsSnapshot.docs) {
        batch.delete(exLogDoc.reference);
      }
      // Delete the day itself
      batch.delete(dayDoc.reference);
    }

    // 4. Delete the program document itself
    batch.delete(_db.collection('programs').doc(programId));

    await batch.commit();
  }

  Stream<double> getProgramProgress(String programId) {
    // We fetch the days count ONCE to be efficient
    return Stream.fromFuture(
      _db.collection('programs').doc(programId).collection('days').get(),
    ).asyncExpand((daysSnap) {
      final totalDays = daysSnap.docs.length;
      if (totalDays == 0) return Stream.value(0.0);

      // Then we listen to the logs collection for real-time updates
      return _db
          .collection('logs')
          .where('programId', isEqualTo: programId)
          .snapshots()
          .map(
            (logsSnap) => (logsSnap.docs.length / totalDays).clamp(0.0, 1.0),
          );
    });
  }

  // To make it reactive to NEW logs, we can use a more combined approach
  Stream<double> getLiveProgramProgress(String programId) {
    final daysStream = _db
        .collection('programs')
        .doc(programId)
        .collection('days')
        .snapshots();
    // final logsStream = _db
    //     .collection('logs')
    //     .where('programId', isEqualTo: programId)
    //     .snapshots();

    // We manually combine them without RxDart
    return daysStream.asyncMap((daysSnap) async {
      final total = daysSnap.docs.length;
      if (total == 0) return 0.0;

      final logsSnap = await _db
          .collection('logs')
          .where('programId', isEqualTo: programId)
          .get();
      return (logsSnap.docs.length / total).clamp(0.0, 1.0);
    });
    // Note: Due to limitations of standard Streams without Rx.combineLatest,
    // this will only update whenever the program STRUCTURE (days) changes.
    // However, we can make the UI listen to logs too or trigger a refresh.
  }

  Future<double> getProgramProgressStatic(String programId) async {
    final days = await _db
        .collection('programs')
        .doc(programId)
        .collection('days')
        .get();
    final logs = await _db
        .collection('logs')
        .where('programId', isEqualTo: programId)
        .get();

    if (days.docs.isEmpty) return 0.0;
    return (logs.docs.length / days.docs.length).clamp(0.0, 1.0);
  }

  Future<void> markProgramNotesAsRead(String programId) async {
    await _db.collection('programs').doc(programId).update({
      'notesReadAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ExerciseLog>> getExerciseLogs(String programId, String dayId) {
    return _db
        .collection('programs')
        .doc(programId)
        .collection('days')
        .doc(dayId)
        .collection('exercise_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExerciseLog.fromMap(doc.data()))
              .toList(),
        );
  }

  // --- Nutrition Logging ---

  Future<void> logNutritionDaily(NutritionLog log) async {
    // Standardize date to midnight for unique daily logs
    final dateOnly = DateTime(log.date.year, log.date.month, log.date.day);

    final existing = await _db
        .collection('nutrition_logs')
        .where('clientId', isEqualTo: log.clientId)
        .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update(log.toMap());
    } else {
      await _db.collection('nutrition_logs').add(log.toMap());
    }
  }

  Stream<NutritionLog?> getTodayNutritionLog(String clientId) {
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);

    return _db
        .collection('nutrition_logs')
        .where('clientId', isEqualTo: clientId)
        .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
        .snapshots()
        .map(
          (snap) => snap.docs.isNotEmpty
              ? NutritionLog.fromMap(snap.docs.first.data(), snap.docs.first.id)
              : null,
        );
  }

  Stream<List<NutritionLog>> getNutritionLogs(String clientId) {
    return _db
        .collection('nutrition_logs')
        .where('clientId', isEqualTo: clientId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => NutritionLog.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<WorkoutDay>> getProgramDays(String programId) {
    return _db
        .collection('programs')
        .doc(programId)
        .collection('days')
        .orderBy('week')
        .orderBy('day')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkoutDay.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> logExerciseProgress(
    String programId,
    String dayId,
    ExerciseLog log,
    String clientId,
  ) async {
    // 0. Auto-cancel reminder for today if first exercise is logged
    final progDoc = await _db.collection('programs').doc(programId).get();
    if (progDoc.exists) {
      final p = Program.fromMap(progDoc.data()!, progDoc.id);
      NotificationService.cancelWorkoutReminder(
        p.assignedClientId ?? '',
        p.name,
        p.currentDay,
      );
    }

    // 1. Save the log to a sub-collection for easier per-exercise tracking
    await _db
        .collection('programs')
        .doc(programId)
        .collection('days')
        .doc(dayId)
        .collection('exercise_logs')
        .doc(log.exerciseName) // One log per exercise name per day
        .set(log.toMap());

    // Notify Coach
    if (progDoc.exists) {
      final p = Program.fromMap(progDoc.data()!, progDoc.id);
      // Send Push Notification to Coach
      await sendPushNotification(
        recipientId: p.coachId,
        title: 'Workout Completed!',
        body: 'Client just finished a session in ${p.name}.',
        data: {'type': 'workout_completion'},
      );
    }

    // 2. Check if all exercises for the day are terminal
    final dayDoc = await _db
        .collection('programs')
        .doc(programId)
        .collection('days')
        .doc(dayId)
        .get();
    final dayData = WorkoutDay.fromMap(dayDoc.data()!, dayDoc.id);

    final logsSnapshot = await _db
        .collection('programs')
        .doc(programId)
        .collection('days')
        .doc(dayId)
        .collection('exercise_logs')
        .get();

    final completedExerciseNames = logsSnapshot.docs
        .map((doc) => ExerciseLog.fromMap(doc.data()))
        .where((l) => l.isTerminal)
        .map((l) => l.exerciseName)
        .toSet();

    bool allTerminal = true;
    for (var ex in dayData.exercises) {
      if (!completedExerciseNames.contains(ex.name)) {
        allTerminal = false;
        break;
      }
    }

    if (allTerminal) {
      await _unlockNextDay(programId, dayData.week, dayData.day);
    }
  }

  Future<void> _unlockNextDay(
    String programId,
    int completedWeek,
    int completedDay,
  ) async {
    final progDoc = await _db.collection('programs').doc(programId).get();
    if (!progDoc.exists) return;

    final prog = Program.fromMap(progDoc.data()!, progDoc.id);

    // Only advance if the day just completed is the current active day
    if (completedWeek != prog.currentWeek || completedDay != prog.currentDay) {
      return;
    }

    // Check total days in current week
    final daysInWeek = await _db
        .collection('programs')
        .doc(programId)
        .collection('days')
        .where('week', isEqualTo: prog.currentWeek)
        .get();

    int maxDayInWeek = 0;
    for (var doc in daysInWeek.docs) {
      final d = (doc.data()['day'] as num?)?.toInt() ?? 0;
      if (d > maxDayInWeek) maxDayInWeek = d;
    }

    if (prog.currentDay < maxDayInWeek) {
      // Unlock next day in same week
      await _db.collection('programs').doc(programId).update({
        'currentDay': prog.currentDay + 1,
      });
    } else if (prog.currentWeek < prog.totalWeeks) {
      // Unlock first day of next week
      await _db.collection('programs').doc(programId).update({
        'currentWeek': prog.currentWeek + 1,
        'currentDay': 1,
      });
    } else {
      // LAST DAY OF LAST WEEK COMPLETED!
      await _db.collection('programs').doc(programId).update({
        'status': ProgramStatus.completed.index,
      });

      // Notify Coach and send message
      final coachId = prog.coachId;
      final clientName =
          "Client"; // In a real app, we'd fetch the client's name or pass it in

      // 1. Send system message to coach
      await sendMessage(
        ChatMessage(
          id: "", // Firebase will generate
          senderId: prog.assignedClientId!,
          receiverId: coachId,
          text: "I've just completed the program: ${prog.name}! 🎉",
          timestamp: DateTime.now(),
          isRead: false,
        ),
      );

      // 2. Trigger push notification for coach
      await sendPushNotification(
        recipientId: coachId,
        title: 'Program Completed! 🎉',
        body:
            '$clientName has successfully finished the program: ${prog.name}.',
        data: {'type': 'program_completion'},
      );
    }
  }

  Future<void> skipExercise(
    String programId,
    String dayId,
    String exerciseName,
    int version,
  ) async {
    final log = ExerciseLog(
      exerciseName: exerciseName,
      sets: [],
      status: ExerciseStatus.skipped,
      programVersion: version,
      timestamp: DateTime.now(),
    );
    await logExerciseProgress(
      programId,
      dayId,
      log,
      "",
    ); // ClientId handled via programId context
  }

  // --- Workout Logging ---
  Future<void> logWorkout(WorkoutLog log) async {
    await _db.collection('logs').add(log.toMap());
  }

  Stream<List<WorkoutLog>> getClientLogs(String clientId) {
    return _db
        .collection('logs')
        .where('clientId', isEqualTo: clientId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkoutLog.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<WorkoutLog?> getWorkoutLogForDay(
    String programId,
    String workoutDayId,
  ) {
    return _db
        .collection('logs')
        .where('programId', isEqualTo: programId)
        .where('workoutDayId', isEqualTo: workoutDayId)
        .orderBy('date', descending: true)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isNotEmpty
              ? WorkoutLog.fromMap(
                  snapshot.docs.first.data(),
                  snapshot.docs.first.id,
                )
              : null,
        );
  }

  Future<void> updateWorkoutFeedback(String logId, String feedback) async {
    await _db.collection('logs').doc(logId).update({'feedback': feedback});
    NotificationService.showLocalNotification(
      'New Coach Feedback',
      'Your coach has left feedback on your recent workout.',
    );
  }

  // --- Aggregate Stats ---
  Stream<Map<String, dynamic>> getClientStats(String clientId) {
    return getClientLogs(clientId).map((logs) {
      if (logs.isEmpty)
        return {
          'consistency': 0,
          'sessions': 0,
          'totalWeight': 0.0,
          'trends': [],
        };

      double totalWeight = 0;
      Map<DateTime, double> dailyVolume = {};
      Map<String, List<Map<String, dynamic>>> exerciseTrends =
          {}; // ExerciseName -> [{date, weight}]

      for (var log in logs) {
        double dayVolume = 0;
        for (var ex in log.exerciseLogs) {
          double maxWeightEx = 0;
          for (var set in ex.sets) {
            dayVolume += set.weight * set.reps;
            if (set.weight > maxWeightEx) maxWeightEx = set.weight;
          }
          totalWeight += dayVolume;

          if (maxWeightEx > 0) {
            exerciseTrends.putIfAbsent(ex.exerciseName, () => []);
            exerciseTrends[ex.exerciseName]!.add({
              'date': log.date,
              'weight': maxWeightEx,
            });
          }
        }
        final date = DateTime(log.date.year, log.date.month, log.date.day);
        dailyVolume[date] = (dailyVolume[date] ?? 0) + dayVolume;
      }

      final sortedDates = dailyVolume.keys.toList()..sort();
      final trends = sortedDates
          .asMap()
          .entries
          .map((e) => {'day': e.key, 'volume': dailyVolume[e.value]})
          .toList();

      // Compute average session rating
      final ratedLogs = logs.where((l) => l.sessionRating != null).toList();
      final double avgRating = ratedLogs.isEmpty
          ? 0.0
          : ratedLogs.map((l) => l.sessionRating!).reduce((a, b) => a + b) /
                ratedLogs.length;

      return {
        'consistency': (logs.length / 5 * 100).clamp(0, 100).toInt(),
        'sessions': logs.length,
        'totalWeight': totalWeight,
        'trends': trends,
        'exerciseTrends': exerciseTrends,
        'avgRating': double.parse(avgRating.toStringAsFixed(1)),
      };
    });
  }

  // --- Data Seeding ---
  Future<void> seedExercises(List<Exercise> exercises) async {
    final batch = _db.batch();
    for (var ex in exercises) {
      final docRef = _db.collection('exercises').doc();
      batch.set(docRef, ex.toMap());
    }
    await batch.commit();
  }

  // --- Real-time Chat ---
  Stream<List<ChatMessage>> getMessages(String user1, String user2) {
    final controller = StreamController<List<ChatMessage>>();
    List<ChatMessage> m1 = [];
    List<ChatMessage> m2 = [];

    void emit() {
      if (controller.isClosed) return;
      final all = [...m1, ...m2];
      all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      controller.add(all);
    }

    final s1 = _db
        .collection('chats')
        .where('senderId', isEqualTo: user1)
        .where('receiverId', isEqualTo: user2)
        .snapshots(includeMetadataChanges: true)
        .listen((snap) {
          m1 = snap.docs
              .map(
                (doc) => ChatMessage.fromMap(
                  doc.data(),
                  doc.id,
                  isPending: doc.metadata.hasPendingWrites,
                ),
              )
              .toList();
          emit();
        });

    final s2 = _db
        .collection('chats')
        .where('senderId', isEqualTo: user2)
        .where('receiverId', isEqualTo: user1)
        .snapshots(includeMetadataChanges: true)
        .listen((snap) {
          m2 = snap.docs
              .map(
                (doc) => ChatMessage.fromMap(
                  doc.data(),
                  doc.id,
                  isPending: doc.metadata.hasPendingWrites,
                ),
              )
              .toList();
          emit();
        });

    controller.onCancel = () {
      s1.cancel();
      s2.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> sendMessage(ChatMessage message) async {
    await _db.collection('chats').add(message.toMap());

    // Fetch sender name for a better notification
    final senderDoc = await _db.collection('users').doc(message.senderId).get();
    final senderName =
        senderDoc.data()?['name'] ??
        (message.senderId == 'coach' ? 'Coach' : 'Client');

    // Send Push Notification to recipient
    await sendPushNotification(
      recipientId: message.receiverId,
      title: 'New Message from $senderName',
      body: message.text,
      data: {'type': 'chat', 'senderId': message.senderId},
    );
  }

  Future<void> sendBroadcastMessage(
    String coachId,
    List<String> clientIds,
    String text,
  ) async {
    final batch = _db.batch();
    final timestamp = DateTime.now();

    for (var clientId in clientIds) {
      final docRef = _db.collection('chats').doc();
      final msg = ChatMessage(
        id: '',
        senderId: coachId,
        receiverId: clientId,
        text: text,
        timestamp: timestamp,
      );
      batch.set(docRef, msg.toMap());
    }

    await batch.commit();
    print('SYSTEM: Broadcast message sent to ${clientIds.length} clients.');
  }

  Future<void> markMessagesAsRead(String senderId, String receiverId) async {
    final unreadMessages = await _db
        .collection('chats')
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Stream<int> getUnreadCount(String senderId, String receiverId) {
    return _db
        .collection('chats')
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getTotalUnreadCountForCoach(String coachId) {
    return _db
        .collection('chats')
        .where('receiverId', isEqualTo: coachId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<Map<String, int>> getUnreadCountsPerClient(String coachId) {
    return _db
        .collection('chats')
        .where('receiverId', isEqualTo: coachId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final Map<String, int> counts = {};
          for (var doc in snapshot.docs) {
            final senderId = doc.data()['senderId'] as String?;
            if (senderId != null) {
              counts[senderId] = (counts[senderId] ?? 0) + 1;
            }
          }
          return counts;
        });
  }

  Stream<String?> getLastMessage(String user1, String user2) {
    return getMessages(user1, user2).map((messages) {
      if (messages.isEmpty) return null;
      return messages.last.text;
    });
  }

  Stream<ChatMessage?> getLastMessageModel(String user1, String user2) {
    return getMessages(user1, user2).map((messages) {
      if (messages.isEmpty) return null;
      return messages.last;
    });
  }

  // --- New Nutrition Plans Feature ---
  Stream<NutritionPlan?> getActiveNutritionPlan(String clientId) {
    return _db
        .collection('users')
        .doc(clientId)
        .collection('nutrition_plans')
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isNotEmpty
              ? NutritionPlan.fromMap(
                  snapshot.docs.first.data(),
                  snapshot.docs.first.id,
                )
              : null,
        );
  }

  Future<void> saveNutritionPlan(NutritionPlan plan) async {
    final docRef = plan.id == null
        ? _db
              .collection('users')
              .doc(plan.clientId)
              .collection('nutrition_plans')
              .doc()
        : _db
              .collection('users')
              .doc(plan.clientId)
              .collection('nutrition_plans')
              .doc(plan.id);

    final planToSave = plan.copyWith(updatedAt: DateTime.now());
    await docRef.set(planToSave.toMap(), SetOptions(merge: true));

    // Notify Client
    await sendPushNotification(
      recipientId: plan.clientId,
      title: 'Nutrition Updated',
      body: 'Your coach updated your nutrition plan.',
      data: {'type': 'nutrition_update'},
    );
  }

  Future<void> markNutritionPlanAsViewed(String clientId, String planId) async {
    await _db
        .collection('users')
        .doc(clientId)
        .collection('nutrition_plans')
        .doc(planId)
        .update({'lastViewedByClient': DateTime.now().millisecondsSinceEpoch});
  }

  // --- Weekly Nutrition Check-Ins ---
  Future<void> saveWeeklyCheckIn(WeeklyNutritionCheckIn checkin) async {
    final docRef = checkin.id == null
        ? _db
              .collection('users')
              .doc(checkin.clientId)
              .collection('nutrition_checkins')
              .doc()
        : _db
              .collection('users')
              .doc(checkin.clientId)
              .collection('nutrition_checkins')
              .doc(checkin.id);

    await docRef.set(
      checkin.copyWith(updatedAt: DateTime.now()).toMap(),
      SetOptions(merge: true),
    );
  }

  Stream<WeeklyNutritionCheckIn?> getLatestWeeklyCheckIn(
    String clientId,
    DateTime weekStartDate,
  ) {
    return _db
        .collection('users')
        .doc(clientId)
        .collection('nutrition_checkins')
        .where('weekStartDate', isEqualTo: weekStartDate.millisecondsSinceEpoch)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isNotEmpty
              ? WeeklyNutritionCheckIn.fromMap(
                  snapshot.docs.first.data(),
                  snapshot.docs.first.id,
                )
              : null,
        );
  }

  Stream<List<WeeklyNutritionCheckIn>> getWeeklyCheckinsForWeek(
    String clientId,
    DateTime weekStartDate,
  ) {
    return _db
        .collection('users')
        .doc(clientId)
        .collection('nutrition_checkins')
        .where('weekStartDate', isEqualTo: weekStartDate.millisecondsSinceEpoch)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WeeklyNutritionCheckIn.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<WeeklyNutritionCheckIn>> getWeeklyCheckInHistory(
    String clientId,
  ) {
    return _db
        .collection('users')
        .doc(clientId)
        .collection('nutrition_checkins')
        .orderBy('weekStartDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WeeklyNutritionCheckIn.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> sendPushNotification({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 1. Fetch recipient's push token
      final userDoc = await _db.collection('users').doc(recipientId).get();
      final pushToken = userDoc.data()?['pushToken'] as String?;

      if (pushToken == null || pushToken.isEmpty) {
        print('SYSTEM: Push skipped for $recipientId - no push token found.');
        return;
      }

      // 2. Create notification document to trigger push (standard pattern for Cloud Functions)
      await _db.collection('notifications').add({
        'token': pushToken,
        'title': title,
        'body': body,
        'data': {
          if (data != null) ...data,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'userId': recipientId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      print('SYSTEM: Push notification queued for $recipientId');
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  // Notifications logic
  Future<void> createNotification(AppNotification notification) async {
    await _db.collection('notifications').add(notification.toMap());

    // Also send push notification
    await sendPushNotification(
      recipientId: notification.recipientId,
      title: notification.title,
      body: notification.body,
      data: {
        'type': notification.type.index.toString(),
        'senderId': notification.senderId,
      },
    );
  }

  Stream<List<AppNotification>> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<int> getUnreadNotificationCount(String userId) {
    return _db
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final snapshot = await _db
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<AppUser?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }
}
