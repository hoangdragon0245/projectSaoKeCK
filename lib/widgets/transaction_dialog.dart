import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/portfolio_provider.dart';
import '../utils/formatters.dart';

class TransactionDialog extends ConsumerStatefulWidget {
  final StockTransaction? editTransaction;
  final String? initialSymbol;
  final TransactionType? initialType;

  const TransactionDialog({
    super.key,
    this.editTransaction,
    this.initialSymbol,
    this.initialType,
  });

  static Future<void> show(
    BuildContext context, {
    StockTransaction? editTransaction,
    String? initialSymbol,
    TransactionType? initialType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDialog(
        editTransaction: editTransaction,
        initialSymbol: initialSymbol,
        initialType: initialType,
      ),
    );
  }

  @override
  ConsumerState<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends ConsumerState<TransactionDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _symbolController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _feeController;
  late TextEditingController _taxController;
  late TextEditingController _noteController;

  late TransactionType _selectedType;
  late DateTime _selectedDate;

  bool _isAutoCalculateFee = true;
  bool _isAutoCalculateTax = true;

  @override
  void initState() {
    super.initState();
    final edit = widget.editTransaction;

    _selectedType = edit?.type ?? widget.initialType ?? TransactionType.buy;
    _selectedDate = edit?.date ?? DateTime.now();

    _symbolController = TextEditingController(
      text: edit?.symbol ?? widget.initialSymbol ?? '',
    );
    _quantityController = TextEditingController(
      text: edit != null ? edit.quantity.toString() : '',
    );
    _priceController = TextEditingController(
      text: edit != null ? edit.price.toStringAsFixed(0) : '',
    );
    _feeController = TextEditingController(
      text: edit != null ? edit.fee.toStringAsFixed(0) : '0',
    );
    _taxController = TextEditingController(
      text: edit != null ? edit.tax.toStringAsFixed(0) : '0',
    );
    _noteController = TextEditingController(text: edit?.note ?? '');

    _quantityController.addListener(_onNumbersChanged);
    _priceController.addListener(_onNumbersChanged);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onNumbersChanged);
    _priceController.removeListener(_onNumbersChanged);
    _symbolController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _feeController.dispose();
    _taxController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onNumbersChanged() {
    final qty = int.tryParse(_quantityController.text.replaceAll(',', '')) ?? 0;
    final price = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0.0;
    final gross = qty * price;

    if (_isAutoCalculateFee) {
      if (_selectedType == TransactionType.buy || _selectedType == TransactionType.sell) {
        // Phí giao dịch thông thường: 0.15%
        final fee = (gross * 0.0015).roundToDouble();
        _feeController.text = fee.toStringAsFixed(0);
      } else {
        _feeController.text = '0';
      }
    }

    if (_isAutoCalculateTax) {
      if (_selectedType == TransactionType.sell) {
        // Thuế bán cổ phiếu tại VN: 0.1% giá trị bán
        final tax = (gross * 0.001).roundToDouble();
        _taxController.text = tax.toStringAsFixed(0);
      } else if (_selectedType == TransactionType.cashDividend) {
        // Thuế cổ tức tiền mặt: 5%
        final tax = (gross * 0.05).roundToDouble();
        _taxController.text = tax.toStringAsFixed(0);
      } else {
        _taxController.text = '0';
      }
    }

    setState(() {});
  }

  void _onTypeChanged(TransactionType newType) {
    setState(() {
      _selectedType = newType;
      _onNumbersChanged();
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final symbol = _symbolController.text.trim().toUpperCase();
    final quantity = int.parse(_quantityController.text.replaceAll(',', ''));
    final price = double.parse(_priceController.text.replaceAll(',', ''));
    final fee = double.tryParse(_feeController.text.replaceAll(',', '')) ?? 0.0;
    final tax = double.tryParse(_taxController.text.replaceAll(',', '')) ?? 0.0;
    final note = _noteController.text.trim();

    final portfolio = ref.read(portfolioProvider);

    // Kiểm tra tính hợp lệ khi Bán
    if (_selectedType == TransactionType.sell && widget.editTransaction == null) {
      final holding = portfolio.holdings.cast<dynamic>().firstWhere(
            (h) => h.symbol == symbol,
            orElse: () => null,
          );
      final currentHeld = holding?.totalQuantity ?? 0;
      if (quantity > currentHeld) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cảnh báo: Bạn chỉ đang nắm giữ $currentHeld CP $symbol. Không thể bán $quantity CP!',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final isEdit = widget.editTransaction != null;
    final id = isEdit ? widget.editTransaction!.id : const Uuid().v4();

    final txn = StockTransaction(
      id: id,
      symbol: symbol,
      type: _selectedType,
      quantity: quantity,
      price: price,
      fee: fee,
      tax: tax,
      date: _selectedDate,
      note: note,
    );

    if (isEdit) {
      ref.read(portfolioProvider.notifier).updateTransaction(txn);
    } else {
      ref.read(portfolioProvider.notifier).addTransaction(txn);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qty = int.tryParse(_quantityController.text.replaceAll(',', '')) ?? 0;
    final price = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0.0;
    final gross = qty * price;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.editTransaction != null
                        ? 'Chỉnh sửa giao dịch'
                        : 'Thêm sao kê giao dịch',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Loại giao dịch Segments
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.buy,
                    label: Text('Mua'),
                    icon: Icon(Icons.add_shopping_cart, size: 16),
                  ),
                  ButtonSegment(
                    value: TransactionType.sell,
                    label: Text('Bán'),
                    icon: Icon(Icons.sell, size: 16),
                  ),
                  ButtonSegment(
                    value: TransactionType.cashDividend,
                    label: Text('Cổ tức'),
                    icon: Icon(Icons.attach_money, size: 16),
                  ),
                  ButtonSegment(
                    value: TransactionType.stockDividend,
                    label: Text('Thưởng'),
                    icon: Icon(Icons.card_giftcard, size: 16),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (set) => _onTypeChanged(set.first),
              ),
              const SizedBox(height: 16),

              // Mã cổ phiếu & Ngày
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _symbolController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Mã cổ phiếu *',
                        hintText: 'VD: HPG, FPT',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.trending_up),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Nhập mã CP' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày giao dịch',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                        child: Text(
                          AppFormatters.formatDate(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Khối lượng & Giá
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _selectedType == TransactionType.stockDividend
                            ? 'Số CP thưởng *'
                            : 'Khối lượng (CP) *',
                        hintText: 'VD: 1000',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = int.tryParse(v?.replaceAll(',', '') ?? '');
                        if (val == null || val <= 0) return 'Số lượng > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _selectedType == TransactionType.cashDividend
                            ? 'Cổ tức / CP (VND)'
                            : (_selectedType == TransactionType.stockDividend
                                ? 'Giá vốn (thường là 0)'
                                : 'Giá khớp (VND) *'),
                        hintText: 'VD: 28500',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = double.tryParse(v?.replaceAll(',', '') ?? '');
                        if (val == null || val < 0) return 'Giá >= 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Thẻ hiển thị giá trị tạm tính
              if (gross > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng giá trị giao dịch:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        AppFormatters.formatVND(gross),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),

              // Phí & Thuế
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _feeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Phí giao dịch (VND)',
                        border: OutlineInputBorder(),
                        helperText: 'Gợi ý: 0.15%',
                      ),
                      onChanged: (_) => _isAutoCalculateFee = false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _taxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Thuế TNCN (VND)',
                        border: OutlineInputBorder(),
                        helperText: 'Bán: 0.1%',
                      ),
                      onChanged: (_) => _isAutoCalculateTax = false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Ghi chú
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  hintText: 'VD: Mua lướt sóng, Đón KQKD quý...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 20),

              // Nút Submit
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType == TransactionType.buy
                      ? const Color(0xFF10B981)
                      : (_selectedType == TransactionType.sell
                          ? const Color(0xFFEF4444)
                          : Colors.blue),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: Text(
                  widget.editTransaction != null
                      ? 'Lưu thay đổi'
                      : 'Xác nhận ghi nhận sao kê',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
