// lib/screens/invoice_history_screen.dart

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/invoice_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'invoice_detail_screen.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  static const _blue = Color(AppConstants.primaryColorValue);

  List<Invoice> _invoices    = [];
  List<Invoice> _filtered    = [];
  bool          _isLoading   = true;
  String        _searchQuery = '';

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper.instance.getAllInvoices();
    setState(() {
      _invoices  = list;
      _filtered  = list;
      _isLoading = false;
    });
  }

  void _search(String q) {
    setState(() {
      _searchQuery = q.toLowerCase().trim();
      if (_searchQuery.isEmpty) {
        _filtered = _invoices;
      } else {
        _filtered = _invoices.where((inv) {
          return inv.customerName.toLowerCase().contains(_searchQuery) ||
              inv.invoiceNo.toString().contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _delete(Invoice inv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text(
            'Delete Invoice #${inv.invoiceNo} for ${inv.customerName}?\nThis cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && inv.id != null) {
      await DatabaseHelper.instance.deleteInvoice(inv.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invoice History'),
            Text('${_invoices.length} invoice${_invoices.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search by name or invoice no…',
                prefixIcon: const Icon(Icons.search, color: _blue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          // ── List ──────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _buildInvoiceCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice inv) {
    final dt  = DateTime.tryParse(inv.dateTime) ?? DateTime.now();
    const col = _blue;

    return Dismissible(
      key: Key('inv_${inv.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      confirmDismiss: (dir) async {
        await _delete(inv);
        return false; // We handle reload ourselves
      },
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceDetailScreen(invoice: inv),
            ),
          );
          _load(); // refresh in case something changed
        },
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFBBDEFB), width: 1)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Invoice number badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('#${inv.invoiceNo}',
                          style: const TextStyle(
                              color: col,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inv.customerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(Helpers.formatDate(dt),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(width: 10),
                          Icon(Icons.shopping_bag_outlined,
                              size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                              '${inv.items.length} item${inv.items.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                      if (inv.customerPhone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(inv.customerPhone,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(Helpers.rupees(inv.grandTotal),
                        style: const TextStyle(
                            color: col,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    const Icon(Icons.chevron_right,
                        size: 18, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No invoices match "$_searchQuery"'
                  : 'No invoices yet',
              style:
                  TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isEmpty)
              Text('Create your first invoice!',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
}
