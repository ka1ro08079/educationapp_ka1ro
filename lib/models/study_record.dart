class StudyRecord {
  final String id;
  final String subject;
  final String content;
  final DateTime createdAt;
  final int minutes;

  StudyRecord({
    required this.id,
    required this.subject,
    required this.content,
    required this.createdAt,
    this.minutes = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'minutes': minutes,
  };

  factory StudyRecord.fromJson(Map<String, dynamic> json) => StudyRecord(
    id: json['id'],
    subject: json['subject'],
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
    minutes: json['minutes'] ?? 0,
  );
}
