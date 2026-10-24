// lib/screens/invoice_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/invoice_model.dart';
import '../services/pdf_generator.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;
  final bool    previewOnly; // true = not yet saved, show no DB actions

  const InvoiceDetailScreen({
    super.key,
    required this.invoice,
    this.previewOnly = false,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  static const _blue = Color(AppConstants.primaryColorValue);

  bool _isGenerating = false;

  Future<void> _printOrShare({bool share = false}) async {
    setState(() => _isGenerating = true);
    try {
      final pdfBytes = await PdfGenerator.generate(widget.invoice);

      if (!mounted) return;

      if (share) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'Invoice_${widget.invoice.invoiceNo}.pdf',
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: 'Invoice_${widget.invoice.invoiceNo}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final dt  = DateTime.tryParse(inv.dateTime) ?? DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Text(widget.previewOnly
            ? 'Invoice Preview'
            : 'Invoice #${inv.invoiceNo}'),
        actions: [
          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _printOrShare(share: true),
              tooltip: 'Share PDF',
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed: () => _printOrShare(share: false),
              tooltip: 'Print PDF',
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.previewOnly)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Preview mode – this invoice has not been saved yet.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // ── Invoice header card ─────────────────────────────────
          _buildHeaderCard(inv, dt),
          const SizedBox(height: 12),

          // ── Customer card ───────────────────────────────────────
          _buildCustomerCard(inv),
          const SizedBox(height: 12),

          // ── Items table ─────────────────────────────────────────
          _buildItemsCard(inv),
          const SizedBox(height: 12),

          // ── Tax summary card ────────────────────────────────────
          _buildTaxSummaryCard(inv),
          const SizedBox(height: 20),

          // ── Print / Share buttons ───────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isGenerating
                      ? null
                      : () => _printOrShare(share: true),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share PDF'),
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
                child: ElevatedButton.icon(
                  onPressed: _isGenerating
                      ? null
                      : () => _printOrShare(share: false),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print Invoice'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Header card ────────────────────────────────────────────────
  Widget _buildHeaderCard(Invoice inv, DateTime dt) => Card(
        color: _blue,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('TAX INVOICE',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              const SizedBox(height: 8),
              const Text(AppConstants.shopName,
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _whiteKv('Invoice No', '#${inv.invoiceNo}'),
                  _whiteKv('Date', Helpers.formatDate(dt)),
                  _whiteKv('Time', Helpers.formatDateTime(dt).split(' ').skip(1).join(' ')),
                ],
              ),
            ],
          ),
        ),
      );

  // ── Customer card ──────────────────────────────────────────────
  Widget _buildCustomerCard(Invoice inv) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Customer Details', Icons.person_outline),
              const Divider(height: 12),
              _infoRow('Name', inv.customerName),
              if (inv.customerAddress.isNotEmpty)
                _infoRow('Address', inv.customerAddress),
              if (inv.customerPhone.isNotEmpty)
                _infoRow('Phone', inv.customerPhone),
            ],
          ),
        ),
      );

  // ── Items card ─────────────────────────────────────────────────
  Widget _buildItemsCard(Invoice inv) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Items', Icons.battery_charging_full),
              const Divider(height: 12),
              ...inv.items.asMap().entries.map((e) {
                final item = e.value;
                final isLast = e.key == inv.items.length - 1;
                return Column(
                  children: [
                    _buildItemRow(item),
                    if (!isLast)
                      const Divider(height: 16, thickness: 0.5),
                  ],
                );
              }),
            ],
          ),
        ),
      );

  Widget _buildItemRow(item) {
    final sn = (item.serialNumbers as String).trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFFE3F2FD),
              child: Text('${item.slNo}',
                  style: const TextStyle(
                      color: _blue, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(item.description,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            Text(Helpers.rupees(item.amount),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: _blue)),
          ],
        ),
        if (sn.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4),
            child: Text('S/N: ${sn.replaceAll('\n', ' | ')}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Wrap(
            spacing: 12,
            children: [
              _chip('Qty: ${item.quantity}'),
              _chip('Rate: ₹${Helpers.formatCurrency(item.rateInclGST)}'),
              if ((item.discountPercent as double) > 0)
                _chip('Disc: ${item.discountPercent}%'),
              _chip('Taxable: ${Helpers.rupees(item.taxableValue)}'),
              _chip('CGST: ${Helpers.rupees(item.cgst)}'),
              _chip('SGST: ${Helpers.rupees(item.sgst)}'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tax summary card ───────────────────────────────────────────
  Widget _buildTaxSummaryCard(Invoice inv) => Card(
        color: const Color(0xFFE8F5E9),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Tax Summary', Icons.receipt_long,
                  color: Colors.green.shade800),
              const Divider(height: 12),
              _sumRow('Total Qty',
                  '${inv.totalQuantity} unit${inv.totalQuantity == 1 ? '' : 's'}'),
              _sumRow('Taxable Amount',
                  Helpers.rupees(inv.totalTaxableValue)),
              _sumRow('CGST @ 9%', Helpers.rupees(inv.totalCGST)),
              _sumRow('SGST @ 9%', Helpers.rupees(inv.totalSGST)),
              const Divider(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('GRAND TOTAL',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    Text(Helpers.rupees(inv.grandTotal),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  // ── Reusable sub-widgets ───────────────────────────────────────
  Widget _sectionTitle(String text, IconData icon, {Color? color}) => Row(
        children: [
          Icon(icon, color: color ?? _blue, size: 18),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: color ?? _blue)),
        ],
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12.5)),
            ),
            const Text(': '),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _sumRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
      );

  Widget _chip(String text) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: const TextStyle(fontSize: 11, color: _blue)),
      );

  Widget _whiteKv(String label, String value) => Column(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ],
      );
}
