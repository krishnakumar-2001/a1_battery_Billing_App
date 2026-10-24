import 'package:flutter_test/flutter_test.dart';
import 'package:a1_battery/utils/number_to_words.dart';

void main() {
  group('NumberToWords Converter Tests', () {
    test('converts zero amount correctly', () {
      expect(NumberToWords.convert(0), equals('Zero Rupees Only'));
    });

    test('converts simple integers correctly', () {
      expect(NumberToWords.convert(1), equals('One Rupee Only'));
      expect(NumberToWords.convert(50), equals('Fifty Rupees Only'));
      expect(NumberToWords.convert(100), equals('One Hundred Rupees Only'));
      expect(NumberToWords.convert(105), equals('One Hundred Five Rupees Only'));
    });

    test('converts thousands and Indian lakhs system', () {
      expect(NumberToWords.convert(1000), equals('One Thousand Rupees Only'));
      expect(NumberToWords.convert(15000), equals('Fifteen Thousand Rupees Only'));
      expect(NumberToWords.convert(100000), equals('One Lakh Rupees Only'));
      expect(NumberToWords.convert(250000), equals('Two Lakh Fifty Thousand Rupees Only'));
    });

    test('converts currency with paise', () {
      expect(NumberToWords.convert(100.50), equals('One Hundred Rupees and Fifty Paise Only'));
      expect(NumberToWords.convert(0.75), equals('Zero Rupees and Seventy Five Paise Only'));
    });
  });
}
