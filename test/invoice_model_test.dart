import 'package:flutter_test/flutter_test.dart';
import 'package:a1_battery/models/invoice_model.dart';
import 'package:a1_battery/models/invoice_item_model.dart';

void main() {
  group('Invoice and InvoiceItem Model Tests', () {
    test('InvoiceItem serializes to and from Json correctly', () {
      const item = InvoiceItem(
        slNo: 1,
        description: 'Amaron Current 150Ah',
        hsnCode: '8507',
        serialNumbers: 'SN123456',
        quantity: 2,
        rateInclGST: 12000.0,
        discountPercent: 5.0,
        taxableValue: 19322.03,
        cgst: 1738.98,
        sgst: 1738.98,
        amount: 22800.0,
      );

      final json = item.toJson();
      final restored = InvoiceItem.fromJson(json);

      expect(restored.slNo, equals(item.slNo));
      expect(restored.description, equals(item.description));
      expect(restored.hsnCode, equals(item.hsnCode));
      expect(restored.quantity, equals(item.quantity));
      expect(restored.rateInclGST, equals(item.rateInclGST));
      expect(restored.discountPercent, equals(item.discountPercent));
      expect(restored.amount, equals(item.amount));
    });

    test('Invoice converts toDbMap and fromDbMap correctly', () {
      const item = InvoiceItem(
        slNo: 1,
        description: 'Luminous Solar 100Ah',
        hsnCode: '8507',
        serialNumbers: 'LUM-9988',
        quantity: 1,
        rateInclGST: 10000.0,
        discountPercent: 0.0,
        taxableValue: 8474.58,
        cgst: 762.71,
        sgst: 762.71,
        amount: 10000.0,
      );

      const invoice = Invoice(
        id: 10,
        invoiceNo: '101',
        dateTime: '2026-03-30T10:00:00Z',
        customerName: 'Suresh Kumar',
        customerAddress: '12 Bazaar St',
        customerPhone: '9876543210',
        customerDistrict: 'Villupuram',
        customerPincode: '605602',
        customerGSTIN: '33BBBBB1111B1Z2',
        customerState: 'Tamil Nadu',
        items: [item],
        totalTaxableValue: 8474.58,
        totalCGST: 762.71,
        totalSGST: 762.71,
        grandTotal: 10000.0,
        totalQuantity: 1,
      );

      final dbMap = invoice.toDbMap();
      final restored = Invoice.fromDbMap(dbMap);

      expect(restored.id, equals(10));
      expect(restored.invoiceNo, equals('101'));
      expect(restored.customerName, equals('Suresh Kumar'));
      expect(restored.customerPhone, equals('9876543210'));
      expect(restored.items.length, equals(1));
      expect(restored.items.first.description, equals('Luminous Solar 100Ah'));
      expect(restored.grandTotal, equals(10000.0));
    });
  });
}
