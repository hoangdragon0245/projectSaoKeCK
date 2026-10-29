import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'vi_VN');
  static final NumberFormat _percentFormat = NumberFormat('+#,##0.00;-#,##0.00', 'vi_VN');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  static String formatVND(double amount, {bool includeSymbol = true}) {
    final formatted = _currencyFormat.format(amount.round());
    return includeSymbol ? '$formatted đ' : formatted;
  }

  static String formatNumber(num number) {
    return _currencyFormat.format(number);
  }

  static String formatPercent(double percent) {
    if (percent == 0) return '0.00%';
    final formatted = _percentFormat.format(percent);
    return '$formatted%';
  }

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Màu sắc tài chính chuẩn: Xanh lá (Lãi), Đỏ (Lỗ), Xám/Vàng (Hòa)
  static Color getPnLColor(double value, {bool isDark = false}) {
    if (value > 0.001) {
      return isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
    } else if (value < -0.001) {
      return isDark ? const Color(0xFFF43F5E) : const Color(0xFFDC2626);
    }
    return isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  }
}
