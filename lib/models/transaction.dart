import 'dart:convert';

enum TransactionType {
  buy,
  sell,
  cashDividend,
  stockDividend;

  String get displayName {
    switch (this) {
      case TransactionType.buy:
        return 'Mua';
      case TransactionType.sell:
        return 'Bán';
      case TransactionType.cashDividend:
        return 'Cổ tức tiền';
      case TransactionType.stockDividend:
        return 'Cổ tức CP / Thưởng';
    }
  }

  static TransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'buy':
      case 'mua':
        return TransactionType.buy;
      case 'sell':
      case 'ban':
      case 'bán':
        return TransactionType.sell;
      case 'cashdividend':
      case 'cash_dividend':
      case 'co_tuc_tien':
      case 'cổ tức tiền':
        return TransactionType.cashDividend;
      case 'stockdividend':
      case 'stock_dividend':
      case 'co_tuc_cp':
      case 'cổ tức cp':
      case 'thưởng':
        return TransactionType.stockDividend;
      default:
        return TransactionType.buy;
    }
  }
}

class StockTransaction {
  final String id;
  final String symbol; // Mã cổ phiếu (VD: HPG, FPT)
  final TransactionType type;
  final int quantity; // Số lượng CP (hoặc số CP nhận cổ tức)
  final double price; // Giá khớp (VND) hoặc số tiền cổ tức/CP
  final double fee; // Phí giao dịch (VND)
  final double tax; // Thuế TNCN (VND)
  final DateTime date;
  final String note;

  StockTransaction({
    required this.id,
    required this.symbol,
    required this.type,
    required this.quantity,
    required this.price,
    this.fee = 0.0,
    this.tax = 0.0,
    required this.date,
    this.note = '',
  });

  /// Tổng giá trị danh nghĩa của lệnh
  double get totalGrossValue => quantity * price;

  /// Tổng tiền thực chi (khi Mua: giá trị + phí) hoặc thực nhận (khi Bán: giá trị - phí - thuế)
  double get totalNetCashFlow {
    switch (type) {
      case TransactionType.buy:
        return -(totalGrossValue + fee);
      case TransactionType.sell:
        return totalGrossValue - fee - tax;
      case TransactionType.cashDividend:
        return (quantity * price) - tax;
      case TransactionType.stockDividend:
        return 0.0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symbol': symbol.toUpperCase(),
      'type': type.name,
      'quantity': quantity,
      'price': price,
      'fee': fee,
      'tax': tax,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory StockTransaction.fromMap(Map<String, dynamic> map) {
    return StockTransaction(
      id: map['id'] as String,
      symbol: (map['symbol'] as String).toUpperCase(),
      type: TransactionType.fromString(map['type'] as String),
      quantity: (map['quantity'] as num).toInt(),
      price: (map['price'] as num).toDouble(),
      fee: (map['fee'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory StockTransaction.fromJson(String source) =>
      StockTransaction.fromMap(json.decode(source) as Map<String, dynamic>);

  StockTransaction copyWith({
    String? id,
    String? symbol,
    TransactionType? type,
    int? quantity,
    double? price,
    double? fee,
    double? tax,
    DateTime? date,
    String? note,
  }) {
    return StockTransaction(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      fee: fee ?? this.fee,
      tax: tax ?? this.tax,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
