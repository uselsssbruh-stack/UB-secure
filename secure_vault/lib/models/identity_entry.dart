import 'package:uuid/uuid.dart';

enum IdentityType { pan, aadhaar, voterId, drivingLicense, other }

extension IdentityTypeLabel on IdentityType {
  String get label {
    switch (this) {
      case IdentityType.pan: return 'PAN Card';
      case IdentityType.aadhaar: return 'Aadhaar Card';
      case IdentityType.voterId: return 'Voter ID';
      case IdentityType.drivingLicense: return 'Driving License';
      case IdentityType.other: return 'Other Document';
    }
  }

  String get icon {
    switch (this) {
      case IdentityType.pan: return '🪪';
      case IdentityType.aadhaar: return '🆔';
      case IdentityType.voterId: return '🗳️';
      case IdentityType.drivingLicense: return '🚗';
      case IdentityType.other: return '📄';
    }
  }

  String get numberHint {
    switch (this) {
      case IdentityType.pan: return 'ABCDE1234F';
      case IdentityType.aadhaar: return '1234 5678 9012';
      case IdentityType.voterId: return 'ABC1234567';
      case IdentityType.drivingLicense: return 'KA0120190001234';
      case IdentityType.other: return 'Document number';
    }
  }

  String get numberDescription {
    switch (this) {
      case IdentityType.pan: return '5 letters + 4 digits + 1 letter';
      case IdentityType.aadhaar: return '12 digits';
      case IdentityType.voterId: return '3 letters + 7 digits';
      case IdentityType.drivingLicense: return 'State code + number';
      case IdentityType.other: return 'Any valid document number';
    }
  }

  int get maxLength {
    switch (this) {
      case IdentityType.pan: return 10;
      case IdentityType.aadhaar: return 14;
      case IdentityType.voterId: return 10;
      case IdentityType.drivingLicense: return 16;
      case IdentityType.other: return 30;
    }
  }
}

class IdentityEntry {
  final String id;
  IdentityType type;
  String number;
  String name;
  String? customDocName; // When type == other
  String? dateOfBirth;
  String? gender;
  String? address;
  String? notes;

  // PAN-specific
  String? fatherMotherName; // Father's/Mother's name

  // Aadhaar-specific
  String? sonDaughterOf; // S/o, D/o, W/o

  // Voter ID-specific
  String? fatherMotherHusbandName; // Father/Mother/Husband name

  // DL-specific
  String? issueDate;
  String? validThrough;
  String? doi; // Date of issue
  String? bloodGroup;
  String? cov; // Class of Vehicle
  String? dlScope; // India / International
  String? sonOf; // Son/Daughter of

  final DateTime createdAt;
  DateTime updatedAt;

  IdentityEntry({
    String? id,
    required this.type,
    required this.number,
    required this.name,
    this.customDocName,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.notes,
    this.fatherMotherName,
    this.sonDaughterOf,
    this.fatherMotherHusbandName,
    this.issueDate,
    this.validThrough,
    this.doi,
    this.bloodGroup,
    this.cov,
    this.dlScope,
    this.sonOf,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get maskedNumber {
    final clean = number.replaceAll(' ', '');
    if (clean.length <= 4) return '•' * clean.length;
    return '${'•' * (clean.length - 4)}${clean.substring(clean.length - 4)}';
  }

  String get formattedAadhaar {
    final clean = number.replaceAll(' ', '');
    if (clean.length != 12) return number;
    return '${clean.substring(0, 4)} ${clean.substring(4, 8)} ${clean.substring(8, 12)}';
  }

  String get displayDocName {
    if (type == IdentityType.other && customDocName != null && customDocName!.isNotEmpty) {
      return customDocName!;
    }
    return type.label;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'number': number,
        'name': name,
        'customDocName': customDocName,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'address': address,
        'notes': notes,
        'fatherMotherName': fatherMotherName,
        'sonDaughterOf': sonDaughterOf,
        'fatherMotherHusbandName': fatherMotherHusbandName,
        'issueDate': issueDate,
        'validThrough': validThrough,
        'doi': doi,
        'bloodGroup': bloodGroup,
        'cov': cov,
        'dlScope': dlScope,
        'sonOf': sonOf,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory IdentityEntry.fromJson(Map<String, dynamic> json) => IdentityEntry(
        id: json['id'] as String,
        type: IdentityType.values.firstWhere((e) => e.name == json['type'], orElse: () => IdentityType.pan),
        number: json['number'] as String,
        name: json['name'] as String,
        customDocName: json['customDocName'] as String?,
        dateOfBirth: json['dateOfBirth'] as String?,
        gender: json['gender'] as String?,
        address: json['address'] as String?,
        notes: json['notes'] as String?,
        fatherMotherName: json['fatherMotherName'] as String?,
        sonDaughterOf: json['sonDaughterOf'] as String?,
        fatherMotherHusbandName: json['fatherMotherHusbandName'] as String?,
        issueDate: json['issueDate'] as String?,
        validThrough: json['validThrough'] as String?,
        doi: json['doi'] as String?,
        bloodGroup: json['bloodGroup'] as String?,
        cov: json['cov'] as String?,
        dlScope: json['dlScope'] as String?,
        sonOf: json['sonOf'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  IdentityEntry copyWith({
    IdentityType? type,
    String? number,
    String? name,
    String? customDocName,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? notes,
    String? fatherMotherName,
    String? sonDaughterOf,
    String? fatherMotherHusbandName,
    String? issueDate,
    String? validThrough,
    String? doi,
    String? bloodGroup,
    String? cov,
    String? dlScope,
    String? sonOf,
  }) {
    return IdentityEntry(
      id: id,
      type: type ?? this.type,
      number: number ?? this.number,
      name: name ?? this.name,
      customDocName: customDocName ?? this.customDocName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      fatherMotherName: fatherMotherName ?? this.fatherMotherName,
      sonDaughterOf: sonDaughterOf ?? this.sonDaughterOf,
      fatherMotherHusbandName: fatherMotherHusbandName ?? this.fatherMotherHusbandName,
      issueDate: issueDate ?? this.issueDate,
      validThrough: validThrough ?? this.validThrough,
      doi: doi ?? this.doi,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      cov: cov ?? this.cov,
      dlScope: dlScope ?? this.dlScope,
      sonOf: sonOf ?? this.sonOf,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
