// lib/utils/constants.dart

class AppConstants {
  // ── Shop Details ──────────────────────────────────────────────
  static const String shopName = '<Your Shop Name>'; // Replace with actual shop name
  static const String shopSubtitle = '<Your Shop Subtitle>'; // Replace with subtitle
  static const String shopAddress = '<Your Shop Full Address>'; // Replace with full address
  static const String shopAddressSingleLine = '<Your Shop Address Single Line>'; // Replace with concise address
  static const String gstin = '<Your GSTIN>'; // Replace with your GSTIN
  static const String stateCode = '<State Code>'; // e.g., '33'
  static const String state = '<State Name>'; // e.g., 'Tamil Nadu'
  static const String phone = '<Contact Phone>'; // e.g., '+91 98765 43210'
  static const String email = '<Contact Email>'; // e.g., 'support@yourdomain.com'

  // ── Bank Details (Sample/Template for Invoicing) ───────────────
  static const String bankAccountHolder = '<Bank Account Holder>'; // e.g., your business name
  static const String bankName = '<Bank Name>'; // e.g., 'HDFC Bank'
  static const String bankAccount = '<Bank Account Number>'; // e.g., '50100000000000'
  static const String bankIfsc = '<IFSC Code>'; // e.g., 'HDFC0000001'
  static const String bankBranch = '<Bank Branch>'; // e.g., 'MAIN BRANCH'

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
