class HoldingStock {
  final String symbol;
  final int totalQuantity;
  final double avgBuyPrice; // Giá vốn bình quân
  final double currentPrice; // Giá thị trường hiện tại

  HoldingStock({
    required this.symbol,
    required this.totalQuantity,
    required this.avgBuyPrice,
    required this.currentPrice,
  });

  /// Tổng vốn đầu tư đang nắm giữ (đã gồm phí mua nếu có)
  double get totalCost => totalQuantity * avgBuyPrice;

  /// Giá trị thị trường hiện tại
  double get marketValue => totalQuantity * currentPrice;

  /// Lãi / Lỗ tạm tính (VND)
  double get unrealizedPnL => marketValue - totalCost;

  /// Tỷ lệ % Lãi / Lỗ tạm tính
  double get unrealizedPnLPercent =>
      totalCost > 0 ? (unrealizedPnL / totalCost) * 100 : 0.0;

  HoldingStock copyWith({
    String? symbol,
    int? totalQuantity,
    double? avgBuyPrice,
    double? currentPrice,
  }) {
    return HoldingStock(
      symbol: symbol ?? this.symbol,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      avgBuyPrice: avgBuyPrice ?? this.avgBuyPrice,
      currentPrice: currentPrice ?? this.currentPrice,
    );
  }
}
