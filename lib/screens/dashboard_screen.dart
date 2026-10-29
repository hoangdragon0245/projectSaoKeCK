import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/holding_stock.dart';
import '../providers/portfolio_provider.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/update_price_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(portfolioProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = state.summary;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thẻ Tổng Quan Tài Sản Chính (Hero Card)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng giá trị danh mục',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${state.holdings.length} mã đang giữ',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppFormatters.formatVND(summary.totalMarketValue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),

                  // Lãi / Lỗ tạm tính
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lãi / Lỗ tạm tính',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  summary.totalUnrealizedPnL >= 0
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: summary.totalUnrealizedPnL >= 0
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFFF87171),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    AppFormatters.formatVND(summary.totalUnrealizedPnL),
                                    style: TextStyle(
                                      color: summary.totalUnrealizedPnL >= 0
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFFF87171),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: summary.totalUnrealizedPnL >= 0
                              ? const Color(0xFF34D399).withOpacity(0.2)
                              : const Color(0xFFF87171).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppFormatters.formatPercent(summary.totalUnrealizedPnLPercent),
                          style: TextStyle(
                            color: summary.totalUnrealizedPnL >= 0
                                ? const Color(0xFF34D399)
                                : const Color(0xFFF87171),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Các chỉ số phụ (Grid 2 cột)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _buildStatTile(
                  context,
                  title: 'Tổng vốn đầu tư',
                  value: AppFormatters.formatVND(summary.totalInvestedCost),
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.blue,
                ),
                _buildStatTile(
                  context,
                  title: 'Lãi đã chốt (Realized)',
                  value: AppFormatters.formatVND(summary.totalRealizedPnL),
                  icon: Icons.monetization_on_outlined,
                  color: AppFormatters.getPnLColor(summary.totalRealizedPnL, isDark: isDark),
                  subtitle: '${summary.totalTradesCount} deal đã bán',
                ),
                _buildStatTile(
                  context,
                  title: 'Cổ tức tiền mặt',
                  value: AppFormatters.formatVND(summary.totalCashDividend),
                  icon: Icons.savings_outlined,
                  color: Colors.amber[700]!,
                ),
                _buildStatTile(
                  context,
                  title: 'Tỷ lệ thắng (Win Rate)',
                  value: '${summary.winRate.toStringAsFixed(1)}%',
                  icon: Icons.emoji_events_outlined,
                  color: Colors.purple,
                  subtitle: '${summary.winTradesCount} thắng / ${summary.lossTradesCount} thua',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Biểu đồ phân bổ danh mục (Pie Chart)
            if (state.holdings.isNotEmpty) ...[
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phân bổ tài sản nắm giữ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 36,
                                  sections: _buildPieChartSections(state.holdings, summary.totalMarketValue),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ListView(
                                shrinkWrap: true,
                                children: state.holdings.map((h) {
                                  final pct = summary.totalMarketValue > 0
                                      ? (h.marketValue / summary.totalMarketValue) * 100
                                      : 0.0;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: _getColorForSymbol(h.symbol),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          h.symbol,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${pct.toStringAsFixed(1)}%',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Danh sách cập nhật giá nhanh (Quick Market Prices)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cập nhật giá thị trường',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Chạm để đổi giá',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (state.holdings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Chưa có mã nào đang nắm giữ.\nHãy thêm giao dịch sao kê mới!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.holdings.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final h = state.holdings[index];
                          final itemPnlColor = AppFormatters.getPnLColor(h.unrealizedPnL, isDark: isDark);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              h.symbol,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Text(
                              'Đang giữ: ${AppFormatters.formatNumber(h.totalQuantity)} CP • Vốn TB: ${AppFormatters.formatVND(h.avgBuyPrice)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: InkWell(
                              onTap: () => UpdatePriceDialog.show(context, h.symbol, h.currentPrice),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          AppFormatters.formatVND(h.currentPrice),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.edit, size: 13, color: Colors.blue),
                                      ],
                                    ),
                                    Text(
                                      AppFormatters.formatPercent(h.unrealizedPnLPercent),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: itemPnlColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TransactionDialog.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm sao kê'),
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    List<HoldingStock> holdings,
    double totalMarketValue,
  ) {
    if (totalMarketValue <= 0) return [];
    return holdings.map((h) {
      final pct = (h.marketValue / totalMarketValue) * 100;
      return PieChartSectionData(
        value: h.marketValue,
        title: '${pct.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        radius: 45,
        color: _getColorForSymbol(h.symbol),
      );
    }).toList();
  }

  Color _getColorForSymbol(String symbol) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
      const Color(0xFF14B8A6),
    ];
    final hash = symbol.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }
}
