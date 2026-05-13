import 'package:uuid/uuid.dart';

class PasswordEntry {
  final String id;
  String title;
  String username;
  String password;
  String? url;
  String? notes;
  final DateTime createdAt;
  DateTime updatedAt;

  PasswordEntry({
    String? id,
    required this.title,
    required this.username,
    required this.password,
    this.url,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'username': username,
        'password': password,
        'url': url,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PasswordEntry.fromJson(Map<String, dynamic> json) => PasswordEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        username: json['username'] as String,
        password: json['password'] as String,
        url: json['url'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  PasswordEntry copyWith({
    String? title,
    String? username,
    String? password,
    String? url,
    String? notes,
  }) {
    return PasswordEntry(
      id: id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
