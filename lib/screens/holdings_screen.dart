import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/holding_stock.dart';
import '../models/transaction.dart';
import '../providers/portfolio_provider.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/update_price_dialog.dart';

class HoldingsScreen extends ConsumerWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(portfolioProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.holdings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline, size: 72, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Danh mục hiện đang trống',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn chưa có mã cổ phiếu nào đang nắm giữ.\nHãy thêm các lệnh mua từ sao kê!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => TransactionDialog.show(context),
                icon: const Icon(Icons.add),
                label: const Text('Thêm giao dịch Mua'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: state.holdings.length,
        itemBuilder: (context, index) {
          final item = state.holdings[index];
          return _buildHoldingCard(context, item, isDark);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TransactionDialog.show(context, initialType: TransactionType.buy),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Mua thêm CP'),
      ),
    );
  }

  Widget _buildHoldingCard(BuildContext context, HoldingStock item, bool isDark) {
    final pnlColor = AppFormatters.getPnLColor(item.unrealizedPnL, isDark: isDark);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Mã CP & Badge % Lãi/Lỗ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.symbol,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${AppFormatters.formatNumber(item.totalQuantity)} CP',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: pnlColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.unrealizedPnL >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: pnlColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppFormatters.formatPercent(item.unrealizedPnLPercent),
                        style: TextStyle(
                          color: pnlColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Giá vốn TB vs Giá thị trường
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giá vốn TB', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.formatVND(item.avgBuyPrice),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Giá thị trường', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () => UpdatePriceDialog.show(context, item.symbol, item.currentPrice),
                      child: Row(
                        children: [
                          Text(
                            AppFormatters.formatVND(item.currentPrice),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 13, color: Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Giá trị TT', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.formatVND(item.marketValue),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dòng Lãi Lỗ Tạm Tính
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: pnlColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lãi / Lỗ tạm tính:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    AppFormatters.formatVND(item.unrealizedPnL),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: pnlColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Nút hành động nhanh
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => TransactionDialog.show(
                      context,
                      initialSymbol: item.symbol,
                      initialType: TransactionType.buy,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Mua thêm'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => TransactionDialog.show(
                      context,
                      initialSymbol: item.symbol,
                      initialType: TransactionType.sell,
                    ),
                    icon: const Icon(Icons.sell, size: 16),
                    label: const Text('Bán chốt'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
