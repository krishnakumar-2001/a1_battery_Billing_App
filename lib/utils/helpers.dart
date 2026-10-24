// lib/utils/helpers.dart

import 'package:intl/intl.dart';

class Helpers {
  static final _currencyFmt = NumberFormat('#,##,##0.00', 'en_IN');
  static final _intFmt      = NumberFormat('#,##,##0',    'en_IN');
  static final _dateFmt     = DateFormat('dd/MM/yyyy');
  static final _dateTimeFmt = DateFormat('dd/MM/yyyy hh:mm a');

  static String formatCurrency(double value) => _currencyFmt.format(value);

  static String formatInt(int value) => _intFmt.format(value);

  static String formatDate(DateTime dt) => _dateFmt.format(dt);

  static String formatDateTime(DateTime dt) => _dateTimeFmt.format(dt);

  static String formatDateTimeStr(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return _dateTimeFmt.format(dt);
    } catch (_) {
      return isoString;
    }
  }

  static String formatDateStr(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return _dateFmt.format(dt);
    } catch (_) {
      return isoString;
    }
  }

  /// Properly round to 2 decimal places avoiding floating-point drift
  static double round2(double value) => (value * 100).round() / 100.0;

  /// Format a double as currency string with ₹ prefix
  static String rupees(double value) => '₹ ${formatCurrency(value)}';
}
