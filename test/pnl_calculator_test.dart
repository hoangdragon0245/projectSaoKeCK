import 'package:flutter_test/flutter_test.dart';
import 'package:saoke_ck/models/transaction.dart';
import 'package:saoke_ck/services/pnl_calculator.dart';

void main() {
  group('PnLCalculator Tests', () {
    test('Calculates Weighted Average Cost and Realized PnL accurately', () {
      final now = DateTime.now();

      final transactions = [
        // 1. Mua 1000 HPG giá 25,000, phí 37,500
        StockTransaction(
          id: '1',
          symbol: 'HPG',
          type: TransactionType.buy,
          quantity: 1000,
          price: 25000,
          fee: 37500,
          date: now.subtract(const Duration(days: 30)),
        ),
        // 2. Mua thêm 1000 HPG giá 27,000, phí 40,500
        StockTransaction(
          id: '2',
          symbol: 'HPG',
          type: TransactionType.buy,
          quantity: 1000,
          price: 27000,
          fee: 40500,
          date: now.subtract(const Duration(days: 20)),
        ),
        // 3. Nhận cổ tức cổ phiếu 20% (400 cổ phiếu)
        StockTransaction(
          id: '3',
          symbol: 'HPG',
          type: TransactionType.stockDividend,
          quantity: 400,
          price: 0,
          date: now.subtract(const Duration(days: 10)),
        ),
        // 4. Bán 1000 HPG giá 30,000, phí 45,000, thuế 30,000
        StockTransaction(
          id: '4',
          symbol: 'HPG',
          type: TransactionType.sell,
          quantity: 1000,
          price: 30000,
          fee: 45000,
          tax: 30000,
          date: now.subtract(const Duration(days: 5)),
        ),
      ];

      final result = PnLCalculator.calculate(
        transactions: transactions,
        customMarketPrices: {'HPG': 32000},
      );

      // Kiểm tra danh mục nắm giữ:
      // Tổng CP ban đầu: 2000 + 400 (thưởng) = 2400. Đã bán 1000 -> còn 1400.
      expect(result.holdings.length, 1);
      final hpg = result.holdings.first;
      expect(hpg.symbol, 'HPG');
      expect(hpg.totalQuantity, 1400);

      // Tổng vốn trước khi bán: 25,037,500 + 27,040,500 = 52,078,000
      // Giá vốn sau pha loãng thưởng 400 CP: 52,078,000 / 2400 = 21,699.16666...
      expect(hpg.avgBuyPrice, closeTo(21699.16, 0.1));

      // Kiểm tra deal đã chốt (Closed Trade):
      expect(result.closedTrades.length, 1);
      final trade = result.closedTrades.first;
      expect(trade.quantity, 1000);
      expect(trade.sellPrice, 30000);
      // Tiền thu ròng = (1000 * 30000) - 45000 - 30000 = 29,925,000
      // Giá vốn 1000 CP = 1000 * 21699.16666... = 21,699,166.67
      // Lãi ròng = 29,925,000 - 21,699,166.67 = 8,225,833.33
      expect(trade.realizedPnL, closeTo(8225833.33, 1.0));
      expect(trade.isWin, true);

      // Kiểm tra Lãi tạm tính cho 1400 CP còn lại với giá thị trường 32,000:
      // Giá trị thị trường = 1400 * 32,000 = 44,800,000
      // Giá vốn 1400 CP = 1400 * 21699.16666... = 30,378,833.33
      // Lãi tạm tính = 44,800,000 - 30,378,833.33 = 14,421,166.67
      expect(hpg.unrealizedPnL, closeTo(14421166.67, 1.0));
    });
  });
}
