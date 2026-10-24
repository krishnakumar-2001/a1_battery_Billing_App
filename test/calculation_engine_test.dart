import 'package:flutter_test/flutter_test.dart';
import 'package:a1_battery/services/calculation_engine.dart';

void main() {
  group('CalculationEngine Tests', () {
    test('buildItem correctly back-calculates 18% GST from inclusive rate', () {
      // Given: 1 item at Rs. 1180 (GST inclusive: 18%)
      // Taxable rate = 1180 / 1.18 = 1000.00
      // Subtotal = 1000.00, Discount = 0
      // CGST (9%) = 90.00, SGST (9%) = 90.00
      // Line amount = 1180.00
      final item = CalculationEngine.buildItem(
        slNo: 1,
        description: 'Exide Inverter Battery 150Ah',
        hsnCode: '8507',
        serialNumbers: 'EX-987654',
        quantity: 1,
        rateInclGST: 1180.0,
        discountPercent: 0.0,
      );

      expect(item.slNo, equals(1));
      expect(item.description, equals('Exide Inverter Battery 150Ah'));
      expect(item.quantity, equals(1));
      expect(item.taxableValue, closeTo(1000.0, 0.01));
      expect(item.cgst, closeTo(90.0, 0.01));
      expect(item.sgst, closeTo(90.0, 0.01));
      expect(item.amount, closeTo(1180.0, 0.01));
    });

    test('buildItem applies discount accurately on taxable value', () {
      // Given: Rate 1180, Qty 1, Discount 10%
      // Taxable per unit = 1000.00
      // Discount = 100.00 -> Taxable value = 900.00
      // CGST (9%) = 81.00, SGST (9%) = 81.00
      // Line amount = 900 + 81 + 81 = 1062.00
      final item = CalculationEngine.buildItem(
        slNo: 2,
        description: 'Amaron Pro 65Ah',
        hsnCode: '8507',
        serialNumbers: 'AM-12345',
        quantity: 1,
        rateInclGST: 1180.0,
        discountPercent: 10.0,
      );

      expect(item.taxableValue, closeTo(900.0, 0.01));
      expect(item.cgst, closeTo(81.0, 0.01));
      expect(item.sgst, closeTo(81.0, 0.01));
      expect(item.amount, closeTo(1062.0, 0.01));
    });

    test('previewItem handles zero and invalid input gracefully', () {
      final zeroItem = CalculationEngine.previewItem(
        quantity: 0,
        rateInclGST: 1000,
        discountPercent: 0,
      );
      expect(zeroItem.amount, equals(0.0));
      expect(zeroItem.taxableValue, equals(0.0));
    });

    test('summarise calculates grand totals and rounds to nearest rupee', () {
      final item1 = CalculationEngine.buildItem(
        slNo: 1,
        description: 'Battery 1',
        hsnCode: '8507',
        serialNumbers: 'SN1',
        quantity: 2,
        rateInclGST: 1180.0,
        discountPercent: 0.0,
      );
      final item2 = CalculationEngine.buildItem(
        slNo: 2,
        description: 'Battery 2',
        hsnCode: '8507',
        serialNumbers: 'SN2',
        quantity: 1,
        rateInclGST: 2360.0,
        discountPercent: 5.0,
      );

      final summary = CalculationEngine.summarise([item1, item2]);

      expect(summary.totalQuantity, equals(3));
      expect(summary.totalTaxableValue, closeTo(item1.taxableValue + item2.taxableValue, 0.05));
      expect(summary.totalCGST, closeTo(item1.cgst + item2.cgst, 0.05));
      expect(summary.totalSGST, closeTo(item1.sgst + item2.sgst, 0.05));
      expect(summary.grandTotal, equals((item1.amount + item2.amount).roundToDouble()));
    });
  });
}
