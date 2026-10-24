// lib/services/calculation_engine.dart
//
// GST Calculation (Rate is GST-INCLUSIVE):
//
//  taxablePerUnit  = rate_incl / 1.18
//  subtotal        = taxablePerUnit × quantity
//  discountAmount  = subtotal × (discount% / 100)
//  taxableValue    = round2(subtotal − discountAmount)
//  cgst            = round2(taxableValue × 0.09)
//  sgst            = round2(taxableValue × 0.09)
//  amount          = round2(taxableValue + cgst + sgst)
//  grandTotal      = roundToNearestRupee(Σ amount)

import '../models/invoice_item_model.dart';
import '../utils/constants.dart';

class CalculationEngine {
  CalculationEngine._();

  // ── Precision helper ──────────────────────────────────────────
  static double round2(double v) => (v * 100).round() / 100.0;

  // ── Single item ───────────────────────────────────────────────
  static InvoiceItem buildItem({
    required int    slNo,
    required String description,
    required String hsnCode,
    required String serialNumbers,
    required int    quantity,
    required double rateInclGST,
    required double discountPercent,
  }) {
    // Ensure no negatives
    final qty      = quantity.clamp(1, 999999);
    final rate     = rateInclGST.clamp(0.0, double.infinity);
    final discount = discountPercent.clamp(0.0, 100.0);

    // Step 1: Back out GST to get taxable rate per unit
    final double taxablePerUnit = rate / AppConstants.gstMultiplier;

    // Step 2: Subtotal of taxable value
    final double subtotal = taxablePerUnit * qty;

    // Step 3: Discount
    final double discountAmount = subtotal * (discount / 100.0);

    // Step 4: Taxable value after discount
    final double taxableValue = round2(subtotal - discountAmount);

    // Step 5: CGST & SGST (9% each)
    final double cgst = round2(taxableValue * (AppConstants.cgstPercent / 100.0));
    final double sgst = round2(taxableValue * (AppConstants.sgstPercent / 100.0));

    // Step 6: Line total
    final double amount = round2(taxableValue + cgst + sgst);

    return InvoiceItem(
      slNo:            slNo,
      description:     description,
      hsnCode:         hsnCode,
      serialNumbers:   serialNumbers,
      quantity:        qty,
      rateInclGST:     rate,
      discountPercent: discount,
      taxableValue:    taxableValue,
      cgst:            cgst,
      sgst:            sgst,
      amount:          amount,
    );
  }

  // ── Live preview totals (from raw field values, no model required) ──
  static ItemPreview previewItem({
    required int    quantity,
    required double rateInclGST,
    required double discountPercent,
  }) {
    if (quantity <= 0 || rateInclGST <= 0) {
      return ItemPreview.zero();
    }
    final disc   = discountPercent.clamp(0.0, 100.0);
    final perU   = rateInclGST / AppConstants.gstMultiplier;
    final sub    = perU * quantity;
    final dAmt   = sub * (disc / 100.0);
    final taxVal = round2(sub - dAmt);
    final cgst   = round2(taxVal * 0.09);
    final sgst   = round2(taxVal * 0.09);
    final amount = round2(taxVal + cgst + sgst);
    return ItemPreview(taxableValue: taxVal, cgst: cgst, sgst: sgst, amount: amount);
  }

  // ── Invoice totals ────────────────────────────────────────────
  static InvoiceSummary summarise(List<InvoiceItem> items) {
    double totalTaxable  = 0;
    double totalCGST     = 0;
    double totalSGST     = 0;
    double runningTotal  = 0;
    int    totalQty      = 0;

    for (final item in items) {
      totalTaxable += item.taxableValue;
      totalCGST    += item.cgst;
      totalSGST    += item.sgst;
      runningTotal += item.amount;
      totalQty     += item.quantity;
    }

    return InvoiceSummary(
      totalTaxableValue: round2(totalTaxable),
      totalCGST:         round2(totalCGST),
      totalSGST:         round2(totalSGST),
      grandTotal:        runningTotal.roundToDouble(),  // round to nearest ₹
      totalQuantity:     totalQty,
    );
  }
}

// ── Value objects ─────────────────────────────────────────────────
class ItemPreview {
  final double taxableValue;
  final double cgst;
  final double sgst;
  final double amount;

  const ItemPreview({
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
    required this.amount,
  });

  factory ItemPreview.zero() => const ItemPreview(
        taxableValue: 0, cgst: 0, sgst: 0, amount: 0);
}

class InvoiceSummary {
  final double totalTaxableValue;
  final double totalCGST;
  final double totalSGST;
  final double grandTotal;
  final int    totalQuantity;

  const InvoiceSummary({
    required this.totalTaxableValue,
    required this.totalCGST,
    required this.totalSGST,
    required this.grandTotal,
    required this.totalQuantity,
  });
}
