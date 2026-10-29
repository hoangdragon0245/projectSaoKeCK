import '../models/closed_trade.dart';
import '../models/holding_stock.dart';
import '../models/portfolio_summary.dart';
import '../models/transaction.dart';

class CalculationResult {
  final List<HoldingStock> holdings;
  final List<ClosedTrade> closedTrades;
  final PortfolioSummary summary;

  CalculationResult({
    required this.holdings,
    required this.closedTrades,
    required this.summary,
  });
}

class PnLCalculator {
  /// Tính toán lại danh mục từ toàn bộ lịch sử sao kê giao dịch
  /// [transactions]: danh sách sao kê
  /// [customMarketPrices]: bảng giá thị trường mới nhất của các mã (nếu có)
  static CalculationResult calculate({
    required List<StockTransaction> transactions,
    Map<String, double> customMarketPrices = const {},
  }) {
    if (transactions.isEmpty) {
      return CalculationResult(
        holdings: [],
        closedTrades: [],
        summary: PortfolioSummary.empty(),
      );
    }

    // Sắp xếp các giao dịch theo thứ tự thời gian tăng dần
    final sortedTxns = List<StockTransaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Bộ nhớ tạm cho từng mã cổ phiếu
    final Map<String, _StockRunningState> runningStates = {};
    final List<ClosedTrade> closedTrades = [];
    double totalCashDividend = 0.0;

    for (final txn in sortedTxns) {
      final symbol = txn.symbol.toUpperCase();
      final state = runningStates.putIfAbsent(symbol, () => _StockRunningState(symbol));

      switch (txn.type) {
        case TransactionType.buy:
          // Thêm vốn và khối lượng:
          // Chi phí mua = (Giá mua * SL) + Phí mua
          final buyCost = (txn.quantity * txn.price) + txn.fee;
          final totalCostBefore = state.quantity * state.avgPrice;
          final newQty = state.quantity + txn.quantity;
          if (newQty > 0) {
            state.avgPrice = (totalCostBefore + buyCost) / newQty;
            state.quantity = newQty;
          }
          state.lastTradedPrice = txn.price;
          break;

        case TransactionType.sell:
          if (state.quantity <= 0) {
            // Không có hàng nhưng có lệnh bán -> xử lý an toàn
            continue;
          }

          final sellQty = txn.quantity > state.quantity ? state.quantity : txn.quantity;
          final costBasis = sellQty * state.avgPrice;
          final grossProceeds = sellQty * txn.price;
          final netProceeds = grossProceeds - txn.fee - txn.tax;
          final pnl = netProceeds - costBasis;
          final pnlPercent = costBasis > 0 ? (pnl / costBasis) * 100 : 0.0;

          closedTrades.add(
            ClosedTrade(
              id: txn.id,
              symbol: symbol,
              sellDate: txn.date,
              quantity: sellQty,
              avgBuyPrice: state.avgPrice,
              sellPrice: txn.price,
              fee: txn.fee,
              tax: txn.tax,
              realizedPnL: pnl,
              realizedPnLPercent: pnlPercent,
            ),
          );

          state.quantity -= sellQty;
          if (state.quantity == 0) {
            state.avgPrice = 0.0;
          }
          state.lastTradedPrice = txn.price;
          break;

        case TransactionType.cashDividend:
          // Cổ tức tiền mặt: Tiền nhận = (Số lượng * Cổ tức/CP) - Thuế
          final netDividend = (txn.quantity * txn.price) - txn.tax;
          totalCashDividend += netDividend;
          break;

        case TransactionType.stockDividend:
          // Cổ tức bằng cổ phiếu / thưởng: Tăng số lượng, tổng giá vốn không đổi
          if (state.quantity > 0) {
            final oldTotalCost = state.quantity * state.avgPrice;
            final newQty = state.quantity + txn.quantity;
            state.avgPrice = oldTotalCost / newQty;
            state.quantity = newQty;
          } else {
            state.quantity += txn.quantity;
            state.avgPrice = 0.0;
          }
          break;
      }
    }

    // Danh sách cổ phiếu đang nắm giữ
    final List<HoldingStock> holdings = [];
    double totalInvestedCost = 0.0;
    double totalMarketValue = 0.0;

    runningStates.forEach((symbol, state) {
      if (state.quantity > 0) {
        // Giá thị trường: ưu tiên giá nhập tùy chỉnh > giá giao dịch gần nhất > giá vốn
        final currentPrice = customMarketPrices[symbol] ??
            (state.lastTradedPrice > 0 ? state.lastTradedPrice : state.avgPrice);

        final holding = HoldingStock(
          symbol: symbol,
          totalQuantity: state.quantity,
          avgBuyPrice: state.avgPrice,
          currentPrice: currentPrice,
        );

        holdings.add(holding);
        totalInvestedCost += holding.totalCost;
        totalMarketValue += holding.marketValue;
      }
    });

    // Sắp xếp mã nắm giữ theo giá trị thị trường giảm dần
    holdings.sort((a, b) => b.marketValue.compareTo(a.marketValue));

    // Sắp xếp các lệnh đã chốt theo ngày bán mới nhất
    closedTrades.sort((a, b) => b.sellDate.compareTo(a.sellDate));

    // Tổng hợp Lãi/Lỗ
    final totalUnrealizedPnL = totalMarketValue - totalInvestedCost;
    final totalUnrealizedPnLPercent =
        totalInvestedCost > 0 ? (totalUnrealizedPnL / totalInvestedCost) * 100 : 0.0;

    double totalRealizedPnL = 0.0;
    int winCount = 0;
    int lossCount = 0;

    for (final trade in closedTrades) {
      totalRealizedPnL += trade.realizedPnL;
      if (trade.realizedPnL > 0) {
        winCount++;
      } else if (trade.realizedPnL < 0) {
        lossCount++;
      }
    }

    final summary = PortfolioSummary(
      totalInvestedCost: totalInvestedCost,
      totalMarketValue: totalMarketValue,
      totalUnrealizedPnL: totalUnrealizedPnL,
      totalUnrealizedPnLPercent: totalUnrealizedPnLPercent,
      totalRealizedPnL: totalRealizedPnL,
      totalCashDividend: totalCashDividend,
      totalTradesCount: closedTrades.length,
      winTradesCount: winCount,
      lossTradesCount: lossCount,
    );

    return CalculationResult(
      holdings: holdings,
      closedTrades: closedTrades,
      summary: summary,
    );
  }
}

class _StockRunningState {
  final String symbol;
  int quantity = 0;
  double avgPrice = 0.0;
  double lastTradedPrice = 0.0;

  _StockRunningState(this.symbol);
}
