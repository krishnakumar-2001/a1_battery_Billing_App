// lib/models/invoice_item_model.dart

class InvoiceItem {
  final int    slNo;
  final String description;
  final String hsnCode;
  final String serialNumbers;   // newline-separated serial numbers
  final int    quantity;
  final double rateInclGST;     // rate entered by user (GST inclusive)
  final double discountPercent;
  final double taxableValue;    // after backing out GST + applying discount
  final double cgst;            // 9%
  final double sgst;            // 9%
  final double amount;          // taxableValue + cgst + sgst

  const InvoiceItem({
    required this.slNo,
    required this.description,
    required this.hsnCode,
    required this.serialNumbers,
    required this.quantity,
    required this.rateInclGST,
    required this.discountPercent,
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'sl_no':           slNo,
    'description':     description,
    'hsn_code':        hsnCode,
    'serial_numbers':  serialNumbers,
    'quantity':        quantity,
    'rate_incl_gst':   rateInclGST,
    'discount_percent': discountPercent,
    'taxable_value':   taxableValue,
    'cgst':            cgst,
    'sgst':            sgst,
    'amount':          amount,
  };

  factory InvoiceItem.fromJson(Map<String, dynamic> j) => InvoiceItem(
    slNo:            j['sl_no'] as int,
    description:     j['description'] as String,
    hsnCode:         j['hsn_code'] as String,
    serialNumbers:   j['serial_numbers'] as String? ?? '',
    quantity:        j['quantity'] as int,
    rateInclGST:     (j['rate_incl_gst'] as num).toDouble(),
    discountPercent: (j['discount_percent'] as num).toDouble(),
    taxableValue:    (j['taxable_value'] as num).toDouble(),
    cgst:            (j['cgst'] as num).toDouble(),
    sgst:            (j['sgst'] as num).toDouble(),
    amount:          (j['amount'] as num).toDouble(),
  );

  @override
  String toString() =>
      'InvoiceItem($slNo. $description x$quantity @ ₹$rateInclGST)';
}
