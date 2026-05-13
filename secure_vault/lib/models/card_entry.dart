import 'package:uuid/uuid.dart';

enum CardType { debit, credit }
enum CardScope { domestic, international, both }

extension CardScopeLabel on CardScope {
  String get label {
    switch (this) {
      case CardScope.domestic: return 'Domestic';
      case CardScope.international: return 'International';
      case CardScope.both: return 'Both';
    }
  }
}

enum CardProvider { visa, mastercard, rupay, amex, discover, dinersClub, maestro, other }

extension CardProviderLabel on CardProvider {
  String get label {
    switch (this) {
      case CardProvider.visa: return 'Visa';
      case CardProvider.mastercard: return 'Mastercard';
      case CardProvider.rupay: return 'RuPay';
      case CardProvider.amex: return 'American Express';
      case CardProvider.discover: return 'Discover';
      case CardProvider.dinersClub: return 'Diners Club';
      case CardProvider.maestro: return 'Maestro';
      case CardProvider.other: return 'Other';
    }
  }
}

// Well-known Indian & international banks
class KnownBanks {
  static const List<String> banks = [
    'State Bank of India (SBI)',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Punjab National Bank (PNB)',
    'Bank of Baroda (BOB)',
    'Canara Bank',
    'Union Bank of India',
    'IndusInd Bank',
    'Yes Bank',
    'IDBI Bank',
    'Bank of India (BOI)',
    'Central Bank of India',
    'Indian Bank',
    'Federal Bank',
    'South Indian Bank',
    'RBL Bank',
    'Bandhan Bank',
    'IDFC First Bank',
    'Citibank',
    'HSBC',
    'Standard Chartered',
    'Deutsche Bank',
    'Barclays',
    'Other',
  ];
}

class CardEntry {
  final String id;
  CardType cardType;
  CardProvider provider;
  String? customProviderName; // When provider == other
  String cardNumber;
  String cardholderName;
  String expiryDate;
  String cvv;
  String? issuingBank;
  String? customBankName; // When issuingBank == 'Other'
  CardScope? scope;
  String? notes;
  final DateTime createdAt;
  DateTime updatedAt;

  CardEntry({
    String? id,
    required this.cardType,
    this.provider = CardProvider.visa,
    this.customProviderName,
    required this.cardNumber,
    required this.cardholderName,
    required this.expiryDate,
    required this.cvv,
    this.issuingBank,
    this.customBankName,
    this.scope,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get displayBank {
    if (issuingBank == 'Other' && customBankName != null && customBankName!.isNotEmpty) {
      return customBankName!;
    }
    return issuingBank ?? '';
  }

  String get displayProvider {
    if (provider == CardProvider.other && customProviderName != null && customProviderName!.isNotEmpty) {
      return customProviderName!;
    }
    return provider.label;
  }

  String get maskedNumber {
    final clean = cardNumber.replaceAll(' ', '');
    if (clean.length < 4) return '•••• •••• •••• ••••';
    final last4 = clean.substring(clean.length - 4);
    return '•••• •••• •••• $last4';
  }

  String get formattedNumber {
    final clean = cardNumber.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  static CardProvider detectProvider(String number) {
    final clean = number.replaceAll(' ', '');
    if (clean.isEmpty) return CardProvider.other;
    if (clean.startsWith('4')) return CardProvider.visa;
    if (clean.startsWith('5') || clean.startsWith('2')) return CardProvider.mastercard;
    if (clean.startsWith('60') || clean.startsWith('65') || clean.startsWith('81') || clean.startsWith('82')) return CardProvider.rupay;
    if (clean.startsWith('34') || clean.startsWith('37')) return CardProvider.amex;
    if (clean.startsWith('6011')) return CardProvider.discover;
    if (clean.startsWith('300') || clean.startsWith('36') || clean.startsWith('38')) return CardProvider.dinersClub;
    if (clean.startsWith('50') || clean.startsWith('56') || clean.startsWith('58')) return CardProvider.maestro;
    return CardProvider.other;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardType': cardType.name,
        'provider': provider.name,
        'customProviderName': customProviderName,
        'cardNumber': cardNumber,
        'cardholderName': cardholderName,
        'expiryDate': expiryDate,
        'cvv': cvv,
        'issuingBank': issuingBank,
        'customBankName': customBankName,
        'scope': scope?.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CardEntry.fromJson(Map<String, dynamic> json) => CardEntry(
        id: json['id'] as String,
        cardType: CardType.values.firstWhere((e) => e.name == json['cardType'], orElse: () => CardType.debit),
        provider: CardProvider.values.firstWhere((e) => e.name == (json['provider'] ?? 'other'), orElse: () => CardProvider.other),
        customProviderName: json['customProviderName'] as String?,
        cardNumber: json['cardNumber'] as String,
        cardholderName: json['cardholderName'] as String,
        expiryDate: json['expiryDate'] as String,
        cvv: json['cvv'] as String,
        issuingBank: json['issuingBank'] as String?,
        customBankName: json['customBankName'] as String?,
        scope: json['scope'] != null ? CardScope.values.firstWhere((e) => e.name == json['scope'], orElse: () => CardScope.domestic) : null,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  CardEntry copyWith({
    CardType? cardType,
    CardProvider? provider,
    String? customProviderName,
    String? cardNumber,
    String? cardholderName,
    String? expiryDate,
    String? cvv,
    String? issuingBank,
    String? customBankName,
    CardScope? scope,
    String? notes,
  }) {
    return CardEntry(
      id: id,
      cardType: cardType ?? this.cardType,
      provider: provider ?? this.provider,
      customProviderName: customProviderName ?? this.customProviderName,
      cardNumber: cardNumber ?? this.cardNumber,
      cardholderName: cardholderName ?? this.cardholderName,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      issuingBank: issuingBank ?? this.issuingBank,
      customBankName: customBankName ?? this.customBankName,
      scope: scope ?? this.scope,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
