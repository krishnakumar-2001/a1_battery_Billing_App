// lib/widgets/product_item_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/calculation_engine.dart';
import '../utils/helpers.dart';

/// Holds all mutable state for a single invoice line item.
class ItemRowController {
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController serialCtrl      = TextEditingController();
  final TextEditingController quantityCtrl    = TextEditingController(text: '1');
  final TextEditingController rateCtrl        = TextEditingController();
  final TextEditingController discountCtrl    = TextEditingController(text: '0');
  String hsnCode = '8507';

  // Live-calculated (read-only display)
  double taxableValue = 0;
  double cgst         = 0;
  double sgst         = 0;
  double amount       = 0;

  void recalculate() {
    final qty      = int.tryParse(quantityCtrl.text) ?? 0;
    final rate     = double.tryParse(rateCtrl.text) ?? 0;
    final discount = double.tryParse(discountCtrl.text) ?? 0;
    final preview  = CalculationEngine.previewItem(
      quantity:        qty,
      rateInclGST:     rate,
      discountPercent: discount,
    );
    taxableValue = preview.taxableValue;
    cgst         = preview.cgst;
    sgst         = preview.sgst;
    amount       = preview.amount;
  }

  void dispose() {
    descriptionCtrl.dispose();
    serialCtrl.dispose();
    quantityCtrl.dispose();
    rateCtrl.dispose();
    discountCtrl.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────
class ProductItemWidget extends StatefulWidget {
  final int                index;
  final ItemRowController  controller;
  final List<String>       products;
  final VoidCallback       onDelete;
  final VoidCallback       onChanged;
  final bool               canDelete;

  const ProductItemWidget({
    super.key,
    required this.index,
    required this.controller,
    required this.products,
    required this.onDelete,
    required this.onChanged,
    this.canDelete = true,
  });

  @override
  State<ProductItemWidget> createState() => _ProductItemWidgetState();
}

class _ProductItemWidgetState extends State<ProductItemWidget> {
  static const _blue   = Color(0xFF1565C0);
  static const _lightB = Color(0xFFE3F2FD);

  ItemRowController get _ctrl => widget.controller;

  void _onFieldChanged() {
    _ctrl.recalculate();
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFBBDEFB), width: 1.2),
      ),
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.white,
                  child: Text(
                    '${widget.index}',
                    style: const TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Item Details',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const Spacer(),
                if (widget.canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.white70, size: 20),
                    onPressed: widget.onDelete,
                    tooltip: 'Remove item',
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // ── Row 1: Battery Name (dropdown) + HSN ───────────
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _dropdownField(
                        label: 'Battery Name *',
                        value: _ctrl.descriptionCtrl.text.isEmpty
                            ? null
                            : _ctrl.descriptionCtrl.text,
                        items: widget.products,
                        onChanged: (v) {
                          if (v != null) {
                            _ctrl.descriptionCtrl.text = v;
                            _onFieldChanged();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: _textField(
                        label: 'HSN/SAC',
                        controller:
                            TextEditingController(text: _ctrl.hsnCode)
                              ..addListener(() {}),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          _ctrl.hsnCode = v;
                        },
                        initialValue: _ctrl.hsnCode,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Row 2: Serial Numbers ───────────────────────────
                _multilineField(
                  label: 'Serial Numbers (one per line)',
                  controller: _ctrl.serialCtrl,
                  hint: 'Enter serial numbers\n(one per line)',
                  maxLines: 3,
                  onChanged: (_) => _onFieldChanged(),
                ),

                const SizedBox(height: 12),

                // ── Row 3: Qty | Rate | Discount ───────────────────
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        label: 'Quantity *',
                        controller: _ctrl.quantityCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (_) => _onFieldChanged(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(
                        label: 'Rate (Incl. GST) ₹',
                        controller: _ctrl.rateCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => _onFieldChanged(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(
                        label: 'Discount %',
                        controller: _ctrl.discountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => _onFieldChanged(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Calculated breakdown ────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _lightB,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _calcRow('Taxable Value',
                          Helpers.rupees(_ctrl.taxableValue)),
                      _calcRow('CGST @ 9%', Helpers.rupees(_ctrl.cgst)),
                      _calcRow('SGST @ 9%', Helpers.rupees(_ctrl.sgst)),
                      const Divider(height: 12, thickness: 0.8),
                      _calcRow(
                        'Item Total',
                        Helpers.rupees(_ctrl.amount),
                        bold: true,
                        color: _blue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget helpers ─────────────────────────────────────────────
  Widget _textField({
    required String label,
    TextEditingController? controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
    String? initialValue,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
      ),
    );
  }

  Widget _multilineField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 3,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.multiline,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        labelStyle: const TextStyle(fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    // Ensure value is in items list
    final safeValue = (value != null && items.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
      ),
      isExpanded: true,
      hint: const Text('Select battery', style: TextStyle(fontSize: 13)),
      items: items
          .map((p) => DropdownMenuItem(
                value: p,
                child: Text(p,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _calcRow(String label, String value,
      {bool bold = false, Color? color}) {
    final style = TextStyle(
      fontSize: 12.5,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
