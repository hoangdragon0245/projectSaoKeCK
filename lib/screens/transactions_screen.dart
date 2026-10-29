import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../providers/portfolio_provider.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_dialog.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(portfolioProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = state.filteredTransactions;

    return Scaffold(
      body: Column(
        children: [
          // Header Tìm kiếm & Bộ lọc
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Thanh tìm kiếm
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm theo mã CP hoặc ghi chú...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: state.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                ref.read(portfolioProvider.notifier).setSearchQuery(''),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                  ),
                  onChanged: (val) =>
                      ref.read(portfolioProvider.notifier).setSearchQuery(val),
                ),
                const SizedBox(height: 10),

                // Bộ lọc Loại và Mã
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Filter Tất cả loại
                      FilterChip(
                        label: const Text('Tất cả'),
                        selected: state.filterType == null,
                        onSelected: (_) =>
                            ref.read(portfolioProvider.notifier).setFilterType(null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Lệnh Mua'),
                        selected: state.filterType == TransactionType.buy,
                        selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF10B981),
                        onSelected: (_) => ref
                            .read(portfolioProvider.notifier)
                            .setFilterType(TransactionType.buy),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Lệnh Bán'),
                        selected: state.filterType == TransactionType.sell,
                        selectedColor: const Color(0xFFEF4444).withOpacity(0.2),
                        checkmarkColor: const Color(0xFFEF4444),
                        onSelected: (_) => ref
                            .read(portfolioProvider.notifier)
                            .setFilterType(TransactionType.sell),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Cổ tức'),
                        selected: state.filterType == TransactionType.cashDividend,
                        selectedColor: Colors.amber.withOpacity(0.2),
                        onSelected: (_) => ref
                            .read(portfolioProvider.notifier)
                            .setFilterType(TransactionType.cashDividend),
                      ),
                      const SizedBox(width: 8),
                      // Dropdown lọc theo Mã CP nếu có
                      if (state.availableSymbols.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withOpacity(0.4)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: state.filterSymbol,
                              hint: const Text('Lọc theo mã CP', style: TextStyle(fontSize: 13)),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Tất cả mã'),
                                ),
                                ...state.availableSymbols.map(
                                  (s) => DropdownMenuItem<String?>(
                                    value: s,
                                    child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                              onChanged: (val) =>
                                  ref.read(portfolioProvider.notifier).setFilterSymbol(val),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Danh sách sao kê
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'Không tìm thấy giao dịch nào',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Thử thay đổi bộ lọc hoặc thêm giao dịch mới',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final item = transactions[index];
                      return _buildTransactionCard(context, ref, item, isDark);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TransactionDialog.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm sao kê'),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    WidgetRef ref,
    StockTransaction txn,
    bool isDark,
  ) {
    Color typeColor;
    IconData typeIcon;
    switch (txn.type) {
      case TransactionType.buy:
        typeColor = const Color(0xFF10B981);
        typeIcon = Icons.arrow_downward;
        break;
      case TransactionType.sell:
        typeColor = const Color(0xFFEF4444);
        typeIcon = Icons.arrow_upward;
        break;
      case TransactionType.cashDividend:
        typeColor = Colors.amber[700]!;
        typeIcon = Icons.attach_money;
        break;
      case TransactionType.stockDividend:
        typeColor = Colors.purple;
        typeIcon = Icons.card_giftcard;
        break;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, size: 14, color: typeColor),
                          const SizedBox(width: 4),
                          Text(
                            txn.type.displayName,
                            style: TextStyle(
                              color: typeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      txn.symbol,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      AppFormatters.formatDate(txn.date),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      padding: EdgeInsets.zero,
                      onSelected: (action) {
                        if (action == 'edit') {
                          TransactionDialog.show(context, editTransaction: txn);
                        } else if (action == 'delete') {
                          _confirmDelete(context, ref, txn);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Xóa', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Detail values
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppFormatters.formatNumber(txn.quantity)} CP @ ${AppFormatters.formatVND(txn.price)}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                Text(
                  AppFormatters.formatVND(txn.totalGrossValue),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ],
            ),

            if (txn.fee > 0 || txn.tax > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Phí: ${AppFormatters.formatVND(txn.fee)} • Thuế: ${AppFormatters.formatVND(txn.tax)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],

            if (txn.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Ghi chú: ${txn.note}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, StockTransaction txn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa giao dịch ${txn.type.displayName} ${txn.quantity} CP ${txn.symbol} ngày ${AppFormatters.formatDate(txn.date)} không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(portfolioProvider.notifier).deleteTransaction(txn.id);
              Navigator.of(context).pop();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
