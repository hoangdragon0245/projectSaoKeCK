import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/portfolio_provider.dart';
import '../services/storage_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String content = '';
        if (file.bytes != null) {
          content = utf8.decode(file.bytes!);
        }
        if (content.isNotEmpty) {
          await ref.read(portfolioProvider.notifier).importTransactionsFromCsv(content);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã import sao kê thành công!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi import file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportCsv(BuildContext context, WidgetRef ref) {
    final state = ref.read(portfolioProvider);
    final csvString = StorageService.exportToCsv(state.transactions);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xuất file Sao kê CSV'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dữ liệu sao kê định dạng CSV:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                height: 180,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csvString,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Sao chép toàn bộ'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvString));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã copy nội dung CSV vào bộ nhớ tạm!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmResetDemo(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nạp dữ liệu mẫu'),
        content: const Text(
          'Dữ liệu sao kê hiện tại sẽ được thay thế bằng danh mục mẫu (HPG, FPT, SSI, MWG). Bạn có muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(portfolioProvider.notifier).resetDemoData();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã nạp dữ liệu mẫu thành công!')),
              );
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sạch dữ liệu'),
        content: const Text(
          'Toàn bộ sao kê và danh mục sẽ bị xóa hoàn toàn. Hành động này không thể hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(portfolioProvider.notifier).clearAll();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa toàn bộ dữ liệu')),
              );
            },
            child: const Text('Xóa hết'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Quản lý dữ liệu
          const Text(
            'Quản lý dữ liệu sao kê',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file, color: Colors.blue),
                  title: const Text('Import sao kê từ CSV'),
                  subtitle: const Text('Nhập nhiều giao dịch cùng lúc từ file CSV'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _importCsv(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.green),
                  title: const Text('Xuất sao kê ra CSV'),
                  subtitle: const Text('Sao chép hoặc lưu trữ dữ liệu sang Excel'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportCsv(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore, color: Colors.amber),
                  title: const Text('Nạp dữ liệu mẫu ban đầu'),
                  subtitle: const Text('Khôi phục danh mục mẫu (HPG, FPT, SSI, MWG)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _confirmResetDemo(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Xóa sạch toàn bộ dữ liệu', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Đặt lại ứng dụng về trạng thái trống'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _confirmClearAll(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Thông tin công thức tài chính
          const Text(
            'Công thức tính toán chuẩn VN',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Giá vốn bình quân gia quyền (WAC):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Khi mua thêm: Giá vốn mới = [(Vốn cũ × SL cũ) + (Giá mua × SL mua) + Phí mua] ÷ Tổng SL mới.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Cổ tức CP / Cổ phiếu thưởng: Tăng số lượng CP, tổng giá vốn giữ nguyên -> Giá vốn bình quân tự động pha loãng giảm xuống.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '2. Lãi / Lỗ đã chốt (Realized P&L):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Khi bán: Lãi ròng = (Giá bán × SL) - (Giá vốn TB × SL) - Phí bán - Thuế bán (0.1%).',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '3. Lãi / Lỗ tạm tính (Unrealized P&L):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Lãi tạm tính = (Giá thị trường - Giá vốn TB) × SL đang nắm giữ.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Giới thiệu phiên bản
          Center(
            child: Column(
              children: [
                Text(
                  'Quản Lý Sao Kê Chứng Khoán v1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hỗ trợ iOS, Web và Desktop',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
