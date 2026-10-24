// lib/models/invoice_model.dart

import 'dart:convert';
import 'invoice_item_model.dart';

class Invoice {
  final int?   id;
  final String invoiceNo;
  final String dateTime;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final String customerDistrict;
  final String customerPincode;
  final String customerGSTIN;
  final String customerState;
  final List<InvoiceItem> items;
  final double totalTaxableValue;
  final double totalCGST;
  final double totalSGST;
  final double grandTotal;
  final int    totalQuantity;

  const Invoice({
    this.id,
    required this.invoiceNo,
    required this.dateTime,
    required this.customerName,
    this.customerAddress  = '',
    this.customerPhone    = '',
    this.customerDistrict = '',
    this.customerPincode  = '',
    this.customerGSTIN    = '',
    this.customerState     = '',
    required this.items,
    required this.totalTaxableValue,
    required this.totalCGST,
    required this.totalSGST,
    required this.grandTotal,
    required this.totalQuantity,
  });

  // ── SQLite row ─────────────────────────────────────────────────
  Map<String, dynamic> toDbMap() => {
    if (id != null) 'id': id,
    'invoice_no':       int.tryParse(invoiceNo) ?? invoiceNo,
    'date_time':        dateTime,
    'customer_name':    customerName,
    'customer_address': customerAddress,
    'customer_phone':   customerPhone,
    'customer_district':customerDistrict,
    'customer_pincode': customerPincode,
    'customer_gstin':   customerGSTIN,
    'customer_state':   customerState,
    'total_amount':     grandTotal,
    'invoice_json':     jsonEncode(_toFullJson()),
  };

  factory Invoice.fromDbMap(Map<String, dynamic> map) {
    final json = jsonDecode(map['invoice_json'] as String) as Map<String, dynamic>;
    final inv = Invoice._fromFullJson(json, id: map['id'] as int?);
    if (map['invoice_no'] != null && inv.invoiceNo.isEmpty) {
      return inv.copyWith(invoiceNo: map['invoice_no'].toString());
    }
    return inv;
  }

  // ── Full JSON (stored inside invoice_json column) ──────────────
  Map<String, dynamic> _toFullJson() => {
    'invoice_no':          invoiceNo,
    'date_time':           dateTime,
    'customer_name':       customerName,
    'customer_address':    customerAddress,
    'customer_phone':      customerPhone,
    'customer_district':   customerDistrict,
    'customer_pincode':    customerPincode,
    'customer_gstin':      customerGSTIN,
    'customer_state':      customerState,
    'items':               items.map((e) => e.toJson()).toList(),
    'total_taxable_value': totalTaxableValue,
    'total_cgst':          totalCGST,
    'total_sgst':          totalSGST,
    'grand_total':         grandTotal,
    'total_quantity':      totalQuantity,
  };

  factory Invoice._fromFullJson(Map<String, dynamic> j, {int? id}) => Invoice(
    id:                 id,
    invoiceNo:          (j['invoice_no'] ?? '').toString(),
    dateTime:           j['date_time'] as String,
    customerName:       j['customer_name'] as String,
    customerAddress:    j['customer_address'] as String? ?? '',
    customerPhone:      j['customer_phone'] as String? ?? '',
    customerDistrict:   j['customer_district'] as String? ?? '',
    customerPincode:    j['customer_pincode'] as String? ?? '',
    customerGSTIN:      j['customer_gstin'] as String? ?? '',
    customerState:      j['customer_state'] as String? ?? '',
    items:              (j['items'] as List)
                            .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
                            .toList(),
    totalTaxableValue:  (j['total_taxable_value'] as num).toDouble(),
    totalCGST:          (j['total_cgst'] as num).toDouble(),
    totalSGST:          (j['total_sgst'] as num).toDouble(),
    grandTotal:         (j['grand_total'] as num).toDouble(),
    totalQuantity:      (j['total_quantity'] as num? ?? 0).toInt(),
  );

  Invoice copyWith({int? id, String? invoiceNo}) => Invoice(
    id:                id ?? this.id,
    invoiceNo:         invoiceNo ?? this.invoiceNo,
    dateTime:          dateTime,
    customerName:      customerName,
    customerAddress:   customerAddress,
    customerPhone:     customerPhone,
    customerDistrict:  customerDistrict,
    customerPincode:   customerPincode,
    customerGSTIN:     customerGSTIN,
    customerState:     customerState,
    items:             items,
    totalTaxableValue: totalTaxableValue,
    totalCGST:         totalCGST,
    totalSGST:         totalSGST,
    grandTotal:        grandTotal,
    totalQuantity:     totalQuantity,
  );
}
