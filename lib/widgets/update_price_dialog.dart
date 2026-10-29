import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/portfolio_provider.dart';
import '../utils/formatters.dart';

class UpdatePriceDialog extends ConsumerStatefulWidget {
  final String symbol;
  final double currentPrice;

  const UpdatePriceDialog({
    super.key,
    required this.symbol,
    required this.currentPrice,
  });

  static Future<void> show(BuildContext context, String symbol, double currentPrice) {
    return showDialog(
      context: context,
      builder: (context) => UpdatePriceDialog(
        symbol: symbol,
        currentPrice: currentPrice,
      ),
    );
  }

  @override
  ConsumerState<UpdatePriceDialog> createState() => _UpdatePriceDialogState();
}

class _UpdatePriceDialogState extends ConsumerState<UpdatePriceDialog> {
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.currentPrice > 0 ? widget.currentPrice.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    final price = double.tryParse(_priceController.text.replaceAll(',', ''));
    if (price != null && price > 0) {
      ref.read(portfolioProvider.notifier).updateMarketPrice(widget.symbol, price);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.price_change_outlined, color: Colors.blue),
          const SizedBox(width: 8),
          Text('Cập nhật giá ${widget.symbol}'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giá hiện tại: ${AppFormatters.formatVND(widget.currentPrice)}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Giá thị trường mới (VND)',
              hintText: 'VD: 31000',
              border: OutlineInputBorder(),
              suffixText: 'đ',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Cập nhật'),
        ),
      ],
    );
  }
}
