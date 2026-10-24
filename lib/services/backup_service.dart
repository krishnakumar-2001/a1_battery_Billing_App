// lib/services/backup_service.dart
//
// AndroidManifest.xml – add these permissions inside <manifest>:
//   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
//   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
//       android:maxSdkVersion="28"/>

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class BackupResult {
  final bool   success;
  final String message;
  const BackupResult({required this.success, required this.message});
}

class BackupService {
  BackupService._();

  static const _backupFileName = 'a1_battery_backup.db';

  // ── Export ───────────────────────────────────────────────────
  /// Copies the SQLite DB file to the app's Documents/Downloads directory
  /// and then opens the share sheet so the user can save it anywhere.
  static Future<BackupResult> exportBackup() async {
    try {
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final dbFile = File(dbPath);

      if (!dbFile.existsSync()) {
        return const BackupResult(success: false, message: 'Database file not found.');
      }

      // Copy to temporary location for sharing
      final tempDir  = await getTemporaryDirectory();
      final destPath = p.join(tempDir.path, _backupFileName);
      await dbFile.copy(destPath);

      // Share / save
      final xFile = XFile(destPath,
          name: _backupFileName, mimeType: 'application/octet-stream');
      await Share.shareXFiles(
        [xFile],
        subject: 'A1 Battery Billing Backup',
        text: 'A1 Battery Billing database backup – $_backupFileName',
      );

      return const BackupResult(
          success: true, message: 'Backup exported successfully.');
    } catch (e) {
      return BackupResult(success: false, message: 'Export failed: $e');
    }
  }

  // ── Import / Restore ─────────────────────────────────────────
  /// Lets the user pick a previously exported .db backup file.
  /// Closes the active DB connection, replaces the file, then re-opens.
  static Future<BackupResult> importBackup() async {
    try {
      // 1. Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return const BackupResult(success: false, message: 'No file selected.');
      }

      final pickedPath = result.files.single.path;
      if (pickedPath == null) {
        return const BackupResult(
            success: false, message: 'Unable to access selected file.');
      }

      // Basic validation – check it looks like an SQLite file
      final pickedFile = File(pickedPath);
      final header     = await pickedFile.openRead(0, 16).first;
      // SQLite magic number: 53 51 4C 69 74 65 20 66 6F 72 6D 61 74 20 33 00
      const sqliteMagic = [83,81,76,105,116,101,32,102,111,114,109,97,116,32,51,0];
      bool validSqlite = true;
      for (int i = 0; i < sqliteMagic.length && i < header.length; i++) {
        if (header[i] != sqliteMagic[i]) { validSqlite = false; break; }
      }
      if (!validSqlite) {
        return const BackupResult(
            success: false, message: 'Invalid backup file. Please select a valid .db file.');
      }

      // 2. Close current DB
      await DatabaseHelper.instance.close();

      // 3. Replace DB file
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      await pickedFile.copy(dbPath);

      // 4. Re-open DB (will be lazy-initialised on next access)
      await DatabaseHelper.instance.database;

      return const BackupResult(
          success: true, message: 'Backup restored successfully. Please restart the app if data appears stale.');
    } catch (e) {
      return BackupResult(success: false, message: 'Restore failed: $e');
    }
  }

  // ── Quick stats for backup screen ────────────────────────────
  static Future<Map<String, dynamic>> getDbInfo() async {
    try {
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final file   = File(dbPath);
      if (!file.existsSync()) return {'size': 0, 'exists': false};
      final stat   = file.statSync();
      return {
        'exists': true,
        'size':   stat.size,
        'sizeKb': (stat.size / 1024).toStringAsFixed(1),
        'path':   dbPath,
      };
    } catch (_) {
      return {'exists': false, 'size': 0};
    }
  }
}
