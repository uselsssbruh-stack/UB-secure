import 'password_entry.dart';
import 'card_entry.dart';
import 'identity_entry.dart';
import 'note_entry.dart';
import 'file_entry.dart';

class VaultModel {
  List<PasswordEntry> passwords;
  List<CardEntry> cards;
  List<IdentityEntry> identities;
  List<NoteEntry> notes;
  List<FileEntry> files;
  DateTime updatedAt;

  VaultModel({
    List<PasswordEntry>? passwords,
    List<CardEntry>? cards,
    List<IdentityEntry>? identities,
    List<NoteEntry>? notes,
    List<FileEntry>? files,
    DateTime? updatedAt,
  })  : passwords = passwords ?? [],
        cards = cards ?? [],
        identities = identities ?? [],
        notes = notes ?? [],
        files = files ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  int get totalItems =>
      passwords.length +
      cards.length +
      identities.length +
      notes.length +
      files.length;

  Map<String, dynamic> toJson() => {
        'passwords': passwords.map((e) => e.toJson()).toList(),
        'cards': cards.map((e) => e.toJson()).toList(),
        'identities': identities.map((e) => e.toJson()).toList(),
        'notes': notes.map((e) => e.toJson()).toList(),
        'files': files.map((e) => e.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory VaultModel.fromJson(Map<String, dynamic> json) => VaultModel(
        passwords: (json['passwords'] as List<dynamic>?)
                ?.map((e) => PasswordEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        cards: (json['cards'] as List<dynamic>?)
                ?.map((e) => CardEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        identities: (json['identities'] as List<dynamic>?)
                ?.map((e) => IdentityEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        notes: (json['notes'] as List<dynamic>?)
                ?.map((e) => NoteEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        files: (json['files'] as List<dynamic>?)
                ?.map((e) => FileEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );

  factory VaultModel.empty() => VaultModel();
}
