class PortfolioSummary {
  final double totalInvestedCost; // Tổng vốn các mã đang giữ
  final double totalMarketValue; // Tổng giá trị thị trường danh mục hiện tại
  final double totalUnrealizedPnL; // Tổng lãi lỗ tạm tính (VND)
  final double totalUnrealizedPnLPercent; // Tổng % lãi lỗ tạm tính
  final double totalRealizedPnL; // Tổng lãi lỗ đã chốt (VND)
  final double totalCashDividend; // Tổng cổ tức tiền mặt đã nhận
  final int totalTradesCount; // Tổng số deal đã bán
  final int winTradesCount; // Số deal chốt lời
  final int lossTradesCount; // Số deal cắt lỗ

  PortfolioSummary({
    required this.totalInvestedCost,
    required this.totalMarketValue,
    required this.totalUnrealizedPnL,
    required this.totalUnrealizedPnLPercent,
    required this.totalRealizedPnL,
    required this.totalCashDividend,
    required this.totalTradesCount,
    required this.winTradesCount,
    required this.lossTradesCount,
  });

  double get winRate =>
      totalTradesCount > 0 ? (winTradesCount / totalTradesCount) * 100 : 0.0;

  /// Tổng hiệu quả ròng toàn bộ (Lãi đã chốt + Cổ tức tiền + Lãi tạm tính)
  double get totalNetWealthPnL =>
      totalRealizedPnL + totalCashDividend + totalUnrealizedPnL;

  factory PortfolioSummary.empty() {
    return PortfolioSummary(
      totalInvestedCost: 0,
      totalMarketValue: 0,
      totalUnrealizedPnL: 0,
      totalUnrealizedPnLPercent: 0,
      totalRealizedPnL: 0,
      totalCashDividend: 0,
      totalTradesCount: 0,
      winTradesCount: 0,
      lossTradesCount: 0,
    );
  }
}
