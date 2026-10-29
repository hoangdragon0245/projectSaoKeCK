import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';

class StorageService {
  static const String _keyTransactions = 'stock_transactions_v1';
  static const String _keyMarketPrices = 'stock_market_prices_v1';

  static Future<List<StockTransaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keyTransactions);
    if (jsonList == null || jsonList.isEmpty) {
      // Nạp dữ liệu mẫu ban đầu để người dùng test ngay lập tức
      final demo = getDemoTransactions();
      await saveTransactions(demo);
      return demo;
    }

    try {
      return jsonList
          .map((item) => StockTransaction.fromJson(item))
          .toList();
    } catch (e) {
      return getDemoTransactions();
    }
  }

  static Future<void> saveTransactions(List<StockTransaction> txns) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = txns.map((t) => t.toJson()).toList();
    await prefs.setStringList(_keyTransactions, jsonList);
  }

  static Future<Map<String, double>> loadMarketPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyMarketPrices);
    if (jsonStr == null || jsonStr.isEmpty) {
      return {
        'HPG': 29500,
        'FPT': 136000,
        'SSI': 34500,
        'MWG': 68200,
        'TCB': 24800,
      };
    }
    try {
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveMarketPrices(Map<String, double> prices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMarketPrices, json.encode(prices));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTransactions);
    await prefs.remove(_keyMarketPrices);
  }

  /// Xuất sao kê ra chuỗi CSV
  static String exportToCsv(List<StockTransaction> txns) {
    final List<List<dynamic>> rows = [];
    // Header
    rows.add([
      'Mã CP',
      'Loại lệnh',
      'Số lượng',
      'Giá khớp',
      'Phí',
      'Thuế',
      'Ngày',
      'Ghi chú',
      'ID',
    ]);

    for (final t in txns) {
      rows.add([
        t.symbol,
        t.type.name,
        t.quantity,
        t.price,
        t.fee,
        t.tax,
        t.date.toIso8601String(),
        t.note,
        t.id,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Đọc dữ liệu từ chuỗi CSV
  static List<StockTransaction> parseCsv(String csvContent) {
    final rows = const CsvToListConverter().convert(csvContent, eol: '\n');
    if (rows.length <= 1) return [];

    final List<StockTransaction> result = [];
    const uuid = Uuid();

    // Bỏ qua dòng header
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.length < 4) continue;

      try {
        final symbol = row[0].toString().trim().toUpperCase();
        final typeStr = row[1].toString().trim();
        final quantity = int.tryParse(row[2].toString().replaceAll(',', '')) ?? 0;
        final price = double.tryParse(row[3].toString().replaceAll(',', '')) ?? 0.0;
        final fee = row.length > 4 ? (double.tryParse(row[4].toString().replaceAll(',', '')) ?? 0.0) : 0.0;
        final tax = row.length > 5 ? (double.tryParse(row[5].toString().replaceAll(',', '')) ?? 0.0) : 0.0;
        DateTime date = DateTime.now();
        if (row.length > 6) {
          final d = DateTime.tryParse(row[6].toString());
          if (d != null) date = d;
        }
        final note = row.length > 7 ? row[7].toString() : '';
        final id = (row.length > 8 && row[8].toString().isNotEmpty)
            ? row[8].toString()
            : uuid.v4();

        if (symbol.isNotEmpty && quantity > 0) {
          result.add(
            StockTransaction(
              id: id,
              symbol: symbol,
              type: TransactionType.fromString(typeStr),
              quantity: quantity,
              price: price,
              fee: fee,
              tax: tax,
              date: date,
              note: note,
            ),
          );
        }
      } catch (_) {
        // Bỏ qua dòng lỗi định dạng
      }
    }

    return result;
  }

  /// Dữ liệu mẫu sao kê thực tế
  static List<StockTransaction> getDemoTransactions() {
    final now = DateTime.now();
    return [
      StockTransaction(
        id: 'demo-1',
        symbol: 'HPG',
        type: TransactionType.buy,
        quantity: 2000,
        price: 26500,
        fee: 79500,
        tax: 0,
        date: now.subtract(const Duration(days: 45)),
        note: 'Mua tích lũy đáy',
      ),
      StockTransaction(
        id: 'demo-2',
        symbol: 'HPG',
        type: TransactionType.buy,
        quantity: 1000,
        price: 27800,
        fee: 41700,
        tax: 0,
        date: now.subtract(const Duration(days: 30)),
        note: 'Mua gia tăng vượt đỉnh ngắn hạn',
      ),
      StockTransaction(
        id: 'demo-3',
        symbol: 'HPG',
        type: TransactionType.sell,
        quantity: 1000,
        price: 30500,
        fee: 45750,
        tax: 30500,
        date: now.subtract(const Duration(days: 15)),
        note: 'Chốt lời 1 phần',
      ),
      StockTransaction(
        id: 'demo-4',
        symbol: 'FPT',
        type: TransactionType.buy,
        quantity: 500,
        price: 125000,
        fee: 93750,
        tax: 0,
        date: now.subtract(const Duration(days: 60)),
        note: 'Cổ phiếu công nghệ tăng trưởng',
      ),
      StockTransaction(
        id: 'demo-5',
        symbol: 'FPT',
        type: TransactionType.stockDividend,
        quantity: 75,
        price: 0,
        fee: 0,
        tax: 0,
        date: now.subtract(const Duration(days: 20)),
        note: 'Nhận cổ tức 15% cổ phiếu thưởng',
      ),
      StockTransaction(
        id: 'demo-6',
        symbol: 'SSI',
        type: TransactionType.buy,
        quantity: 1500,
        price: 33000,
        fee: 74250,
        tax: 0,
        date: now.subtract(const Duration(days: 25)),
        note: 'Đón sóng KRX',
      ),
      StockTransaction(
        id: 'demo-7',
        symbol: 'MWG',
        type: TransactionType.buy,
        quantity: 1000,
        price: 64000,
        fee: 96000,
        tax: 0,
        date: now.subtract(const Duration(days: 35)),
        note: 'Bách Hóa Xanh hòa vốn',
      ),
      StockTransaction(
        id: 'demo-8',
        symbol: 'MWG',
        type: TransactionType.cashDividend,
        quantity: 1000,
        price: 500,
        fee: 0,
        tax: 25000,
        date: now.subtract(const Duration(days: 12)),
        note: 'Nhận 5% cổ tức tiền mặt',
      ),
    ];
  }
}
