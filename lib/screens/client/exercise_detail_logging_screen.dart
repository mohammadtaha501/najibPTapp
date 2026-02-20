import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:ptapp/models/program_model.dart';
import 'package:ptapp/models/log_model.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/utils/theme.dart';

class ExerciseDetailLoggingScreen extends StatefulWidget {
  final Program program;
  final WorkoutDay workoutDay;
  final dynamic
  exercise; // Using dynamic because it's from the WorkoutDay.exercises list
  final ExerciseLog? existingLog;
  final DateTime? sessionStartTime;

  const ExerciseDetailLoggingScreen({
    super.key,
    required this.program,
    required this.workoutDay,
    required this.exercise,
    this.existingLog,
    this.sessionStartTime,
  });

  @override
  State<ExerciseDetailLoggingScreen> createState() =>
      _ExerciseDetailLoggingScreenState();
}

class _ExerciseDetailLoggingScreenState
    extends State<ExerciseDetailLoggingScreen>
    with TickerProviderStateMixin {
  late YoutubePlayerController _ytController;
  final DatabaseService _dbService = DatabaseService();
  final List<TextEditingController> _weightControllers = [];
  final List<TextEditingController> _repsControllers = [];
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  bool _hasVideo = false;

  // --- Rest Timer State ---
  static const int _defaultRestSeconds = 60;
  int _restDuration = _defaultRestSeconds;
  int _restRemaining = 0;
  bool _isRestTimerActive = false;
  Timer? _restTimer;

  // --- Audio Players for Timer Sounds ---
  final List<AudioPlayer> _activePlayers = [];
  AudioPlayer? _alarmPlayer;
  static bool _audioContextConfigured = false;

  void _ensureAudioContext() {
    if (_audioContextConfigured) return;
    _audioContextConfigured = true;
    final ctx = AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        audioMode: AndroidAudioMode.normal,
        usageType: AndroidUsageType.notification,
        contentType: AndroidContentType.sonification,
      ),
    );
    AudioPlayer.global.setAudioContext(ctx);
  }

  void _playSound(String assetPath) {
    final player = AudioPlayer();
    _activePlayers.add(player);
    player.play(AssetSource(assetPath)).catchError((_) {});
    player.onPlayerComplete.listen((_) {
      player.dispose();
      _activePlayers.remove(player);
    });
  }

  @override
  void initState() {
    super.initState();
    _ensureAudioContext();
    _hasVideo =
        widget.exercise.videoUrl != null &&
        widget.exercise.videoUrl!.isNotEmpty;
    if (_hasVideo) {
      final videoId =
          YoutubePlayer.convertUrlToId(widget.exercise.videoUrl!) ?? '';
      _ytController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      );
    }

    final setsCount = int.tryParse(widget.exercise.sets.toString()) ?? 1;
    for (int i = 0; i < setsCount; i++) {
      String initialWeight = widget.exercise.targetWeight?.toString() ?? '';
      String initialReps = widget.exercise.reps?.toString() ?? '';

      if (widget.existingLog != null && widget.existingLog!.sets.length > i) {
        initialWeight = widget.existingLog!.sets[i].weight.toString();
        initialReps = widget.existingLog!.sets[i].reps.toString();
      }

      _weightControllers.add(TextEditingController(text: initialWeight));
      _repsControllers.add(TextEditingController(text: initialReps));
    }
    _notesController.text = widget.existingLog?.notes ?? '';
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    for (final p in _activePlayers) {
      p.dispose();
    }
    _activePlayers.clear();
    _alarmPlayer?.dispose();
    if (_hasVideo) _ytController.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    for (var c in _weightControllers) {
      c.dispose();
    }
    for (var c in _repsControllers) {
      c.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    _alarmPlayer?.stop();
    setState(() {
      _restRemaining = _restDuration;
      _isRestTimerActive = true;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restRemaining <= 1) {
        timer.cancel();
        _alarmPlayer?.dispose();
        _alarmPlayer = AudioPlayer();
        _alarmPlayer!.play(AssetSource('audio/alarm.wav'));
        HapticFeedback.heavyImpact();
        setState(() => _isRestTimerActive = false);
      } else {
        if (_restRemaining <= 10) {
          _playSound('audio/tick_fast.wav');
        } else {
          _playSound('audio/tick.wav');
        }
        setState(() => _restRemaining--);
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    for (final p in _activePlayers) {
      p.stop();
    }
    _alarmPlayer?.stop();
    setState(() => _isRestTimerActive = false);
  }

  // ─────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_hasVideo) {
      return _buildScaffold(context, null);
    }
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        if (!_ytController.value.isPlaying) _ytController.pause();
      },
      player: YoutubePlayer(
        controller: _ytController,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppTheme.primaryColor,
        onReady: () => _ytController.addListener(() {}),
      ),
      builder: (context, player) => _buildScaffold(context, player),
    );
  }

  Widget _buildScaffold(BuildContext context, Widget? player) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Sleek App Bar ──
              SliverAppBar(
                expandedHeight: _hasVideo ? 56 : 56,
                pinned: true,
                backgroundColor: AppTheme.backgroundColor,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  widget.exercise.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
              ),

              // ── Body ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Video Player ──
                      if (_hasVideo && player != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: player,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Prescription Card ──
                      _buildPrescriptionCard(),

                      // ── Description ──
                      if (widget.exercise.description != null &&
                          widget.exercise.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          icon: Icons.info_outline,
                          title: 'Description',
                          child: Text(
                            widget.exercise.description!,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

                      // ── Coaching Note ──
                      if (widget.exercise.note != null &&
                          widget.exercise.note!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.sticky_note_2_outlined,
                          title: 'Coach\'s Note',
                          child: Text(
                            widget.exercise.note!,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── Rest Timer Controls ──
                      _buildRestTimerControls(),

                      const SizedBox(height: 24),

                      // ── Log Progress Header ──
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'LOG YOUR SETS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Set Rows ──
                      ...List.generate(
                        _weightControllers.length,
                        (index) => _buildSetRow(index),
                      ),

                      const SizedBox(height: 20),

                      // ── Exercise Notes ──
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Exercise Notes',
                            hintText: 'e.g. "Felt tight in hamstrings..."',
                            prefixIcon: Icon(
                              Icons.edit_note,
                              color: Colors.white.withValues(alpha: 0.3),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Action Buttons ──
                      _buildActionButtons(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Rest Timer Overlay ──
          if (_isRestTimerActive) _buildRestTimerOverlay(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  PRESCRIPTION CARD
  // ─────────────────────────────────────────────────

  Widget _buildPrescriptionCard() {
    final ex = widget.exercise;

    // Build the list of prescription chips dynamically
    final List<_PrescriptionItem> items = [];
    if (ex.sets != null) {
      items.add(_PrescriptionItem('Sets', ex.sets.toString(), Icons.repeat));
    }
    if (ex.reps != null && ex.reps!.isNotEmpty) {
      items.add(
        _PrescriptionItem('Reps', ex.reps!, Icons.format_list_numbered),
      );
    }
    if (ex.targetWeight != null && ex.targetWeight!.isNotEmpty) {
      items.add(
        _PrescriptionItem(
          'Weight',
          '${ex.targetWeight}kg',
          Icons.fitness_center,
        ),
      );
    }
    if (ex.restTime != null) {
      items.add(
        _PrescriptionItem('Rest', '${ex.restTime}s', Icons.timer_outlined),
      );
    }
    if (ex.tempo != null && ex.tempo!.isNotEmpty) {
      items.add(_PrescriptionItem('Tempo', ex.tempo!, Icons.speed));
    }
    if (ex.rpe != null && ex.rpe!.isNotEmpty) {
      items.add(_PrescriptionItem('RPE', ex.rpe!, Icons.bolt));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.08),
            AppTheme.surfaceColor,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 16,
                color: AppTheme.primaryColor.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Text(
                'PRESCRIPTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: AppTheme.primaryColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items
                .map((item) => _buildPrescriptionChip(item))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionChip(_PrescriptionItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.4),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  INFO CARD (Description / Coach Note)
  // ─────────────────────────────────────────────────

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppTheme.mutedTextColor),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedTextColor,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  REST TIMER CONTROLS
  // ─────────────────────────────────────────────────

  Widget _buildRestTimerControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rest Timer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Between sets',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
          // Duration adjuster
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => setState(
                    () => _restDuration = (_restDuration - 15).clamp(15, 300),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Icon(
                      Icons.remove,
                      size: 16,
                      color: AppTheme.mutedTextColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: Text(
                    '${_restDuration}s',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(
                    () => _restDuration = (_restDuration + 15).clamp(15, 300),
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Icon(
                      Icons.add,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  REST TIMER OVERLAY
  // ─────────────────────────────────────────────────

  Widget _buildRestTimerOverlay() {
    final double progress = _restRemaining / _restDuration;
    final Color timerColor = progress > 0.33
        ? AppTheme.primaryColor
        : Colors.orangeAccent;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 16, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A2E).withValues(alpha: 0.95),
              const Color(0xFF151528),
            ],
          ),
          border: Border(
            top: BorderSide(color: timerColor.withValues(alpha: 0.4)),
          ),
          boxShadow: [
            BoxShadow(
              color: timerColor.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular timer
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      '$_restRemaining',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Resting...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Next set in ${_restRemaining}s',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _stopRestTimer,
              icon: const Icon(Icons.skip_next, size: 18),
              label: const Text('SKIP'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white54,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  SET ROW
  // ─────────────────────────────────────────────────

  Widget _buildSetRow(int index) {
    String target = '';
    if (widget.exercise.targetWeight != null &&
        widget.exercise.targetWeight!.isNotEmpty) {
      target += '${widget.exercise.targetWeight}kg ';
    }
    if (widget.exercise.reps != null && widget.exercise.reps!.isNotEmpty) {
      target += '× ${widget.exercise.reps}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // Set header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Set ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              if (target.isNotEmpty) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    target.trim(),
                    style: const TextStyle(
                      color: AppTheme.mutedTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Input row
          Row(
            children: [
              Expanded(
                child: _buildCompactInput(
                  controller: _weightControllers[index],
                  label: 'Weight (kg)',
                  icon: Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCompactInput(
                  controller: _repsControllers[index],
                  label: 'Reps',
                  icon: Icons.tag,
                ),
              ),
              const SizedBox(width: 10),
              // Timer button
              GestureDetector(
                onTap: _startRestTimer,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.15),
                        AppTheme.primaryColor.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.timer,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
          isDense: true,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  ACTION BUTTONS
  // ─────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary: Save & Complete
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => _saveProgress(markAsTerminal: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'SAVE & COMPLETE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        // Secondary: Save / Skip
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _saveProgress(markAsTerminal: false),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text(
                    'SAVE',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _skipExercise,
                  icon: const Icon(Icons.skip_next, size: 18),
                  label: const Text(
                    'SKIP',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent.withValues(alpha: 0.8),
                    side: BorderSide(
                      color: Colors.redAccent.withValues(alpha: 0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────
  //  DATA METHODS
  // ─────────────────────────────────────────────────

  Future<void> _saveProgress({required bool markAsTerminal}) async {
    setState(() => _isLoading = true);

    final List<SetLog> sets = [];
    for (int i = 0; i < _weightControllers.length; i++) {
      sets.add(
        SetLog(
          weight: double.tryParse(_weightControllers[i].text) ?? 0,
          reps: int.tryParse(_repsControllers[i].text) ?? 0,
        ),
      );
    }

    final log = ExerciseLog(
      exerciseName: widget.exercise.name,
      sets: sets,
      notes: _notesController.text,
      status: markAsTerminal
          ? ExerciseStatus.completed
          : ExerciseStatus.inProgress,
      programVersion: widget.program.version,
      timestamp: DateTime.now(),
      sessionStartTime: widget.sessionStartTime,
    );

    await _dbService.logExerciseProgress(
      widget.program.id!,
      widget.workoutDay.id!,
      log,
      "",
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _skipExercise() async {
    setState(() => _isLoading = true);
    await _dbService.skipExercise(
      widget.program.id!,
      widget.workoutDay.id!,
      widget.exercise.name,
      widget.program.version,
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

// Helper class for prescription items
class _PrescriptionItem {
  final String label;
  final String value;
  final IconData icon;

  _PrescriptionItem(this.label, this.value, this.icon);
}
