// lib/utils/constants.dart

class AppConstants {
  // ── Shop Details ──────────────────────────────────────────────
  static const String shopName = 'A1 BATTERY & POWER ENTERPRISES';
  static const String shopSubtitle = 'Automobile & Inverter Batteries';
  static const String shopAddress =
      'No. 2, Salem Main Road, Ulundurpet, Kallakurichi District, Tamil Nadu - 606107';
  static const String shopAddressSingleLine =
      'No. 2, Salem Main Road, Ulundurpet, Kallakurichi - 606107';
  static const String gstin = '33AAAAA0000A1Z5'; // Sample GSTIN format (State code 33: Tamil Nadu)
  static const String stateCode = '33';
  static const String state = 'Tamil Nadu';
  static const String phone = '+91 98765 43210';
  static const String email = 'support@a1battery.example.com';

  // ── Bank Details (Sample/Template for Invoicing) ───────────────
  static const String bankAccountHolder = 'A1 BATTERY & POWER';
  static const String bankName = 'HDFC Bank';
  static const String bankAccount = '50100000000000';
  static const String bankIfsc = 'HDFC0000001';
  static const String bankBranch = 'MAIN BRANCH';

  // ── GST Config ───────────────────────────────────────────────
  static const double gstRatePercent = 18.0;
  static const double cgstPercent = 9.0;
  static const double sgstPercent = 9.0;
  static const double gstMultiplier = 1.18; // 1 + 18/100

  // ── Default HSN for Batteries ────────────────────────────────
  static const String defaultHsn = '8507';

  // ── Invoice Declaration ──────────────────────────────────────
  static const String declaration =
      'We declare that this invoice shows the actual price of the goods '
      'described and that all particulars are true and correct.';

  // ── Default Products ─────────────────────────────────────────
  static const List<String> defaultProducts = [
    'Amaron Battery',
    'Exide Battery',
    'Luminous Battery',
    'SF Sonic Battery',
    'Okaya Battery',
    'Livguard Battery',
    'Tata Green Battery',
    'Powerzone Battery',
    'Prestolite Battery',
    'Other Battery',
  ];

  // ── UI Colors ────────────────────────────────────────────────
  static const int primaryColorValue = 0xFF1565C0;
  static const int accentColorValue = 0xFF0D47A1;
  static const int successColorValue = 0xFF2E7D32;
}
