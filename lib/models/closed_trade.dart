class ClosedTrade {
  final String id;
  final String symbol;
  final DateTime sellDate;
  final int quantity;
  final double avgBuyPrice;
  final double sellPrice;
  final double fee;
  final double tax;
  final double realizedPnL; // Lãi/lỗ ròng thực tế đã trừ phí & thuế
  final double realizedPnLPercent; // % Lãi/lỗ dựa trên giá vốn

  ClosedTrade({
    required this.id,
    required this.symbol,
    required this.sellDate,
    required this.quantity,
    required this.avgBuyPrice,
    required this.sellPrice,
    required this.fee,
    required this.tax,
    required this.realizedPnL,
    required this.realizedPnLPercent,
  });

  double get totalSellGross => quantity * sellPrice;
  double get totalBuyCost => quantity * avgBuyPrice;
  bool get isWin => realizedPnL > 0;
}
