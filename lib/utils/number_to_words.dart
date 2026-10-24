// lib/utils/number_to_words.dart

class NumberToWords {
  static const List<String> _ones = [
    '',        'One',       'Two',       'Three',    'Four',
    'Five',    'Six',       'Seven',     'Eight',    'Nine',
    'Ten',     'Eleven',    'Twelve',    'Thirteen', 'Fourteen',
    'Fifteen', 'Sixteen',   'Seventeen', 'Eighteen', 'Nineteen',
  ];

  static const List<String> _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty',
    'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety',
  ];

  // Converts a double amount to "X Rupees and Y Paise Only" (Indian system)
  static String convert(double amount) {
    // Round to nearest paise
    final int totalPaise = (amount * 100).round();
    final int rupees     = totalPaise ~/ 100;
    final int paise      = totalPaise % 100;

    String result = '';

    if (rupees > 0) {
      result += '${_toIndianWords(rupees)} Rupee${rupees == 1 ? '' : 's'}';
    } else {
      result = 'Zero Rupees';
    }

    if (paise > 0) {
      result += ' and ${_toWords(paise)} Paise';
    }

    return '$result Only';
  }

  /// Converts integer using Indian number system:
  /// Crores → Lakhs → Thousands → Hundreds → below 100
  static String _toIndianWords(int n) {
    if (n == 0) return '';

    final buffer = StringBuffer();

    if (n >= 10000000) {
      buffer.write('${_toIndianWords(n ~/ 10000000)} Crore');
      n %= 10000000;
      if (n > 0) buffer.write(' ');
    }
    if (n >= 100000) {
      buffer.write('${_toIndianWords(n ~/ 100000)} Lakh');
      n %= 100000;
      if (n > 0) buffer.write(' ');
    }
    if (n >= 1000) {
      buffer.write('${_toIndianWords(n ~/ 1000)} Thousand');
      n %= 1000;
      if (n > 0) buffer.write(' ');
    }
    if (n > 0) {
      buffer.write(_toWords(n));
    }

    return buffer.toString().trim();
  }

  /// Handles numbers 1–999
  static String _toWords(int n) {
    if (n == 0) return '';
    if (n < 20) return _ones[n];
    if (n < 100) {
      final t = _tens[n ~/ 10];
      final o = n % 10 == 0 ? '' : ' ${_ones[n % 10]}';
      return '$t$o';
    }
    // 100–999
    final hundreds = _ones[n ~/ 100];
    final rest     = n % 100;
    if (rest == 0) return '$hundreds Hundred';
    return '$hundreds Hundred ${_toWords(rest)}';
  }
}
