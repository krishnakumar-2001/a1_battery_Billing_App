// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/backup_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _blue = Color(AppConstants.primaryColorValue);

  List<String> _products = [];
  bool _loading = false;
  String _dbSize = '…';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final products = await DatabaseHelper.instance.getProducts();
    final info = await BackupService.getDbInfo();
    setState(() {
      _products = products;
      _dbSize = info['sizeKb'] != null ? '${info['sizeKb']} KB' : 'Unknown';
    });
  }

  // ── Export Backup ─────────────────────────────────────────────
  Future<void> _exportBackup() async {
    setState(() => _loading = true);
    final result = await BackupService.exportBackup();
    setState(() => _loading = false);
    _showMessage(result.message, success: result.success);
  }

  // ── Import Backup ─────────────────────────────────────────────
  Future<void> _importBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'Restoring a backup will replace ALL current data.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    final result = await BackupService.importBackup();
    setState(() => _loading = false);
    _showMessage(result.message, success: result.success);
    if (result.success) _loadData();
  }

  // ── Add Product ───────────────────────────────────────────────
  Future<void> _addProduct() async {
    final ctrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Battery Product'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Battery Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (res != null && res.isNotEmpty) {
      await DatabaseHelper.instance.addProduct(res);
      _loadData();
    }
  }

  // ── Delete Product ────────────────────────────────────────────
  Future<void> _deleteProduct(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Product'),
        content: Text('Remove "$name" from product list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteProduct(name);
      _loadData();
    }
  }

  void _showMessage(String msg, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Shop Info ──────────────────────────────────────
                _buildSection(
                  title: 'Shop Information',
                  icon: Icons.store_outlined,
                  children: [
                    _tile('Shop Name', AppConstants.shopName),
                    _tile('GSTIN', AppConstants.gstin),
                    _tile('State', AppConstants.state),
                    _tile('Phone', AppConstants.phone),
                    _tile('Email', AppConstants.email),
                    _tile('Address', AppConstants.shopAddressSingleLine),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Backup ─────────────────────────────────────────
                _buildSection(
                  title: 'Backup & Restore',
                  icon: Icons.backup_outlined,
                  children: [
                    _tile('Database Size', _dbSize),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _exportBackup,
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Export Backup'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _blue,
                              side: const BorderSide(color: _blue),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _importBackup,
                            icon: const Icon(Icons.download_outlined, size: 18),
                            label: const Text('Restore'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade800,
                              side: BorderSide(color: Colors.orange.shade700),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Export saves a .db file you can share via email/Drive\n'
                      '• Restore will overwrite all current data',
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Products ───────────────────────────────────────
                _buildSection(
                  title: 'Battery Products (${_products.length})',
                  icon: Icons.battery_charging_full,
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: _blue, size: 24),
                    onPressed: _addProduct,
                    tooltip: 'Add product',
                  ),
                  children: _products.isEmpty
                      ? [
                          Text('No products found.',
                              style: TextStyle(color: Colors.grey.shade600))
                        ]
                      : _products
                          .map((p) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: const Icon(Icons.battery_full_outlined,
                                    size: 18, color: _blue),
                                title: Text(p,
                                    style: const TextStyle(fontSize: 14)),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red.shade400),
                                  onPressed: () => _deleteProduct(p),
                                ),
                              ))
                          .toList(),
                ),

                const SizedBox(height: 16),

                // ── App Info ───────────────────────────────────────
                _buildSection(
                  title: 'App Information',
                  icon: Icons.info_outline,
                  children: [
                    _tile('App Name', 'A1 Battery Billing Pro'),
                    _tile('Version', '1.0.0'),
                    _tile('GST Rate', '18% (CGST 9% + SGST 9%)'),
                    _tile('HSN (Default)', AppConstants.defaultHsn),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: _blue, size: 18),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _blue)),
                  const Spacer(),
                  if (trailing != null) trailing,
                ],
              ),
              const Divider(height: 14),
              ...children,
            ],
          ),
        ),
      );

  Widget _tile(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(label,
                  style:
                      TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
            ),
            const Text(': '),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}
