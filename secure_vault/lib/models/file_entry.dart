import 'package:uuid/uuid.dart';

class FileEntry {
  final String id;
  String fileName;
  String originalName;
  String mimeType;
  int fileSize;
  final DateTime createdAt;
  DateTime updatedAt;

  FileEntry({
    String? id,
    required this.fileName,
    required this.originalName,
    required this.mimeType,
    required this.fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage =>
      mimeType.startsWith('image/') ||
      originalName.toLowerCase().endsWith('.png') ||
      originalName.toLowerCase().endsWith('.jpg') ||
      originalName.toLowerCase().endsWith('.jpeg');

  bool get isPdf =>
      mimeType == 'application/pdf' ||
      originalName.toLowerCase().endsWith('.pdf');

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'originalName': originalName,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FileEntry.fromJson(Map<String, dynamic> json) => FileEntry(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        originalName: json['originalName'] as String,
        mimeType: json['mimeType'] as String,
        fileSize: json['fileSize'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
