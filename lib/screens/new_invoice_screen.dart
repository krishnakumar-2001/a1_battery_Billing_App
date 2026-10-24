// lib/screens/new_invoice_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/invoice_item_model.dart';
import '../models/invoice_model.dart';
import '../services/calculation_engine.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/product_item_widget.dart';
import 'invoice_detail_screen.dart';

class NewInvoiceScreen extends StatefulWidget {
  const NewInvoiceScreen({super.key});

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  static const _blue  = Color(AppConstants.primaryColorValue);
  static const _lightB = Color(0xFFE3F2FD);

  final _formKey               = GlobalKey<FormState>();
  final _invoiceNoCtrl         = TextEditingController();
  final _invoiceDateCtrl       = TextEditingController();
  final _customerNameCtrl      = TextEditingController();
  final _customerAddressCtrl   = TextEditingController();
  final _customerPhoneCtrl     = TextEditingController();
  final _customerDistrictCtrl  = TextEditingController();
  final _customerPincodeCtrl   = TextEditingController();
  final _customerGstinCtrl     = TextEditingController();
  final _customerStateCtrl     = TextEditingController();

  final List<ItemRowController> _items = [];
  List<String> _products = [];
  String _nextInvoiceNo  = '1';
  DateTime _invoiceDate  = DateTime.now();
  bool   _isSaving       = false;

  // Live totals
  double _totalTaxable = 0;
  double _totalCGST    = 0;
  double _totalSGST    = 0;
  double _grandTotal   = 0;
  int    _totalQty     = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final no       = await DatabaseHelper.instance.getNextInvoiceNo();
    final products = await DatabaseHelper.instance.getProducts();
    if (mounted) {
      setState(() {
        _nextInvoiceNo        = no;
        _invoiceNoCtrl.text   = no;
        _invoiceDateCtrl.text = DateFormat('dd/MM/yyyy').format(_invoiceDate);
        _products             = products;
      });
    }
    _addItem(); // Start with one item
  }

  Future<void> _pickInvoiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _invoiceDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _invoiceDate.hour,
          _invoiceDate.minute,
          _invoiceDate.second,
        );
        _invoiceDateCtrl.text = DateFormat('dd/MM/yyyy').format(_invoiceDate);
      });
    }
  }

  @override
  void dispose() {
    _invoiceNoCtrl.dispose();
    _invoiceDateCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerAddressCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _customerDistrictCtrl.dispose();
    _customerPincodeCtrl.dispose();
    _customerGstinCtrl.dispose();
    _customerStateCtrl.dispose();
    for (final c in _items) { c.dispose(); }
    super.dispose();
  }

  // ── Item management ───────────────────────────────────────────
  void _addItem() {
    setState(() => _items.add(ItemRowController()));
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
    _recalcTotals();
  }

  void _recalcTotals() {
    double totalTaxable = 0, totalCGST = 0, totalSGST = 0,
           grandTotal   = 0;
    int    totalQty     = 0;

    for (final c in _items) {
      c.recalculate();
      totalTaxable += c.taxableValue;
      totalCGST    += c.cgst;
      totalSGST    += c.sgst;
      grandTotal   += c.amount;
      totalQty     += int.tryParse(c.quantityCtrl.text) ?? 0;
    }

    setState(() {
      _totalTaxable = CalculationEngine.round2(totalTaxable);
      _totalCGST    = CalculationEngine.round2(totalCGST);
      _totalSGST    = CalculationEngine.round2(totalSGST);
      _grandTotal   = grandTotal.roundToDouble();
      _totalQty     = totalQty;
    });
  }

  // ── Build Invoice model ───────────────────────────────────────
  Invoice? _buildInvoice() {
    final builtItems = <InvoiceItem>[];

    for (int i = 0; i < _items.length; i++) {
      final c    = _items[i];
      final desc = c.descriptionCtrl.text.trim();
      final qty  = int.tryParse(c.quantityCtrl.text) ?? 0;
      final rate = double.tryParse(c.rateCtrl.text) ?? 0;
      final disc = double.tryParse(c.discountCtrl.text) ?? 0;

      if (desc.isEmpty || qty == 0 || rate == 0) continue;

      builtItems.add(CalculationEngine.buildItem(
        slNo:            i + 1,
        description:     desc,
        hsnCode:         c.hsnCode,
        serialNumbers:   c.serialCtrl.text.trim(),
        quantity:        qty,
        rateInclGST:     rate,
        discountPercent: disc,
      ));
    }

    if (builtItems.isEmpty) return null;

    final summary = CalculationEngine.summarise(builtItems);
    final invNo = _invoiceNoCtrl.text.trim().isNotEmpty
        ? _invoiceNoCtrl.text.trim()
        : _nextInvoiceNo;

    return Invoice(
      invoiceNo:         invNo,
      dateTime:          _invoiceDate.toIso8601String(),
      customerName:      _customerNameCtrl.text.trim(),
      customerAddress:   _customerAddressCtrl.text.trim(),
      customerPhone:     _customerPhoneCtrl.text.trim(),
      customerDistrict:  _customerDistrictCtrl.text.trim(),
      customerPincode:   _customerPincodeCtrl.text.trim(),
      customerGSTIN:     _customerGstinCtrl.text.trim(),
      customerState:     _customerStateCtrl.text.trim(),
      items:             builtItems,
      totalTaxableValue: summary.totalTaxableValue,
      totalCGST:         summary.totalCGST,
      totalSGST:         summary.totalSGST,
      grandTotal:        summary.grandTotal,
      totalQuantity:     summary.totalQuantity,
    );
  }

  // ── Validate & Save ───────────────────────────────────────────
  Future<void> _saveInvoice() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final invoice = _buildInvoice();
    if (invoice == null) {
      _snack('Please add at least one valid item with battery name, qty and rate.',
          isError: true);
      return;
    }

    final exists = await DatabaseHelper.instance.checkInvoiceNoExists(invoice.invoiceNo);
    if (!mounted) return;
    if (exists) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invoice Number Exists'),
          content: Text(
            'Invoice #${invoice.invoiceNo} already exists in records.\nDo you want to overwrite it or choose another number?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel / Change'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Overwrite'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isSaving = true);

    try {
      final id      = await DatabaseHelper.instance.insertInvoice(invoice);
      final saved   = invoice.copyWith(id: id);

      if (!mounted) return;
      // Navigate to detail/print screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(invoice: saved),
        ),
      );
    } catch (e) {
      _snack('Failed to save invoice: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Preview PDF ───────────────────────────────────────────────
  Future<void> _previewPdf() async {
    final invoice = _buildInvoice();
    if (invoice == null) {
      _snack('Please fill in all required fields first.', isError: true);
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(invoice: invoice, previewOnly: true),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Manage products ───────────────────────────────────────────
  Future<void> _showAddProductDialog() async {
    final ctrl = TextEditingController();
    final res  = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Product'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Battery name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (res != null && res.isNotEmpty) {
      await DatabaseHelper.instance.addProduct(res);
      final products = await DatabaseHelper.instance.getProducts();
      setState(() => _products = products);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currentInvNo = _invoiceNoCtrl.text.trim().isEmpty
        ? _nextInvoiceNo
        : _invoiceNoCtrl.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Invoice', style: TextStyle(fontSize: 18)),
            Text('Invoice #$currentInvNo',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            onPressed: _previewPdf,
            tooltip: 'Preview PDF',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInvoiceDetailsCard(),
            const SizedBox(height: 12),
            _buildCustomerCard(),
            const SizedBox(height: 12),
            _buildItemsHeader(),
            ..._items.asMap().entries.map((e) => ProductItemWidget(
                  key: ValueKey(e.key),
                  index:      e.key + 1,
                  controller: e.value,
                  products:   _products,
                  canDelete:  _items.length > 1,
                  onDelete:   () => _removeItem(e.key),
                  onChanged:  _recalcTotals,
                )),
            const SizedBox(height: 8),
            _buildAddItemRow(),
            const SizedBox(height: 16),
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Invoice Details Card (Manual define Invoice No. & Date) ───
  Widget _buildInvoiceDetailsCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, color: _blue, size: 20),
                  const SizedBox(width: 8),
                  Text('Invoice Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600, color: _blue)),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      setState(() {
                        _invoiceNoCtrl.text = _nextInvoiceNo;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _lightB,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, size: 14, color: _blue),
                          SizedBox(width: 4),
                          Text('Auto #',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _blue,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _invoiceNoCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _inputDeco('Invoice Number *').copyWith(
                        prefixIcon: const Icon(Icons.tag, color: _blue, size: 20),
                        hintText: 'e.g. 2, 101, etc.',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Invoice number is required'
                          : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _invoiceDateCtrl,
                      readOnly: true,
                      onTap: _pickInvoiceDate,
                      decoration: _inputDeco('Date').copyWith(
                        prefixIcon: const Icon(Icons.calendar_today_outlined,
                            color: _blue, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  // ── Customer card ─────────────────────────────────────────────
  Widget _buildCustomerCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, color: _blue, size: 20),
                  const SizedBox(width: 8),
                  Text('Customer Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600, color: _blue)),
                ],
              ),
              const Divider(height: 16),
              TextFormField(
                controller: _customerNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDeco('Customer Name *'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Customer name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerAddressCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: _inputDeco('Address (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDeco('Phone (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customerDistrictCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDeco('District'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _customerPincodeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco('Pincode'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerGstinCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDeco('GSTIN/UIN'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerStateCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDeco('State Name'),
              ),
            ],
          ),
        ),
      );

  // ── Items header ──────────────────────────────────────────────
  Widget _buildItemsHeader() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.battery_charging_full, color: _blue, size: 20),
            const SizedBox(width: 8),
            Text('Items',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600, color: _blue)),
            const Spacer(),
            TextButton.icon(
              onPressed: _showAddProductDialog,
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('New Product', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );

  // ── Add item row ──────────────────────────────────────────────
  Widget _buildAddItemRow() => Center(
        child: OutlinedButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add),
          label: const Text('Add Another Item'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _blue,
            side: const BorderSide(color: _blue),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );

  // ── Summary card ──────────────────────────────────────────────
  Widget _buildSummaryCard() => Card(
        color: _blue,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Row(children: [
                Icon(Icons.receipt_long, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Invoice Summary',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ]),
              const SizedBox(height: 12),
              _sumRow('Total Qty',     '$_totalQty unit${_totalQty == 1 ? '' : 's'}'),
              _sumRow('Taxable Amount', Helpers.rupees(_totalTaxable)),
              _sumRow('CGST @ 9%',     Helpers.rupees(_totalCGST)),
              _sumRow('SGST @ 9%',     Helpers.rupees(_totalSGST)),
              const Divider(color: Colors.white38, height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('GRAND TOTAL',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  Text(Helpers.rupees(_grandTotal),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _sumRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  // ── Action buttons ────────────────────────────────────────────
  Widget _buildActionButtons() => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : _previewPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Preview'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _blue,
                side: const BorderSide(color: _blue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveInvoice,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Saving…' : 'Save & Print'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      );

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
      );
}
