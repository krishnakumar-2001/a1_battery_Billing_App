// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/invoice_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'new_invoice_screen.dart';
import 'invoice_history_screen.dart';
import 'settings_screen.dart';
import 'invoice_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _blue = Color(AppConstants.primaryColorValue);
  static const _accent = Color(AppConstants.accentColorValue);

  Map<String, dynamic> _stats = {'count': 0, 'total': 0.0};
  List<Invoice> _recent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    final stats = await DatabaseHelper.instance.getStats();
    final recent = await DatabaseHelper.instance.getRecentInvoices(limit: 5);
    setState(() {
      _stats = stats;
      _recent = recent;
      _loading = false;
    });
  }

  Future<void> _deleteInvoice(Invoice inv) async {
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
      _loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: CustomScrollView(
        slivers: [
          // ── App bar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: _blue,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_blue, _accent],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/image.png',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('GEE POWER',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1)),
                                Text('Billing APP',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(AppConstants.shopSubtitle,
                            style:
                                TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text('GEE POWER',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadDashboard,
              ),
            ],
          ),

          // ── Body ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  _buildStatsRow(),
                  const SizedBox(height: 20),

                  // Quick actions
                  const Text('Quick Actions',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _blue)),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Recent invoices
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Invoices',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: _blue)),
                      TextButton(
                        onPressed: () => _goTo(const InvoiceHistoryScreen()),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildRecentList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── FAB ─────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goTo(const NewInvoiceScreen()),
        backgroundColor: _blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Invoice',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 4,
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final count = _stats['count'] as int;
    final total = (_stats['total'] as num).toDouble();

    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'Total Invoices',
            value: '$count',
            icon: Icons.receipt_long_outlined,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'Total Revenue',
            value: Helpers.rupees(total),
            icon: Icons.currency_rupee,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 2),
              Text(title,
                  style:
                      TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
            ],
          ),
        ),
      );

  // ── Quick actions ─────────────────────────────────────────────
  Widget _buildQuickActions() => Row(
        children: [
          Expanded(
            child: _actionCard(
              label: 'New Invoice',
              icon: Icons.add_circle_outline,
              color: _blue,
              onTap: () => _goTo(const NewInvoiceScreen()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionCard(
              label: 'History',
              icon: Icons.history,
              color: Colors.purple.shade700,
              onTap: () => _goTo(const InvoiceHistoryScreen()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionCard(
              label: 'Settings',
              icon: Icons.settings_outlined,
              color: Colors.teal.shade700,
              onTap: () => _goTo(const SettingsScreen()),
            ),
          ),
        ],
      );

  Widget _actionCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );

  // ── Recent invoices list ──────────────────────────────────────
  Widget _buildRecentList() {
    if (_loading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ));
    }

    if (_recent.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text('No invoices yet',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
              const SizedBox(height: 4),
              Text('Tap the button below to create one!',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recent.map((inv) {
        final dt = DateTime.tryParse(inv.dateTime) ?? DateTime.now();
        return Dismissible(
          key: Key('recent_${inv.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          confirmDismiss: (dir) async {
            await _deleteInvoice(inv);
            return false;
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InvoiceDetailScreen(invoice: inv),
                  ),
                );
                _loadDashboard();
              },
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#${inv.invoiceNo}',
                    style: const TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
              ),
              title: Text(inv.customerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(Helpers.formatDate(dt),
                  style: const TextStyle(fontSize: 12)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Helpers.rupees(inv.grandTotal),
                      style: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _goTo(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    _loadDashboard();
  }
}
