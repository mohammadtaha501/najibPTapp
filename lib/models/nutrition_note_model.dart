import 'package:cloud_firestore/cloud_firestore.dart';

enum NutritionNoteStatus { draft, active }

class NutritionNote {
  final String? id;
  final String clientId;
  final String title;
  final String summary;
  final String content;
  final NutritionNoteStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastViewedByClient;

  NutritionNote({
    this.id,
    required this.clientId,
    required this.title,
    required this.summary,
    required this.content,
    this.status = NutritionNoteStatus.draft,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastViewedByClient,
  })  : this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'title': title,
      'summary': summary,
      'content': content,
      'status': status.index,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastViewedByClient': lastViewedByClient != null ? Timestamp.fromDate(lastViewedByClient!) : null,
    };
  }

  factory NutritionNote.fromMap(Map<String, dynamic> map, String id) {
    return NutritionNote(
      id: id,
      clientId: map['clientId'] ?? '',
      title: map['title'] ?? '',
      summary: map['summary'] ?? '',
      content: map['content'] ?? '',
      status: NutritionNoteStatus.values[map['status'] ?? 0],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      lastViewedByClient: (map['lastViewedByClient'] as Timestamp?)?.toDate(),
    );
  }

  NutritionNote copyWith({
    String? id,
    String? clientId,
    String? title,
    String? summary,
    String? content,
    NutritionNoteStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastViewedByClient,
  }) {
    return NutritionNote(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastViewedByClient: lastViewedByClient ?? this.lastViewedByClient,
    );
  }
}
