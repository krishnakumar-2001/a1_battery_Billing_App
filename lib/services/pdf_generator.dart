// lib/services/pdf_generator.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../utils/constants.dart';
import '../utils/number_to_words.dart';
import '../utils/helpers.dart';

class PdfGenerator {
  PdfGenerator._();

  static const _borderColor = PdfColors.black;
  static const _border = pw.BorderSide(width: 0.5, color: _borderColor);

  static pw.TextStyle _style({
    double size = 8.5,
    bool bold = false,
    bool italic = false,
    PdfColor? color,
  }) =>
      pw.TextStyle(
        font: bold
            ? pw.Font.helveticaBold()
            : italic
                ? pw.Font.helveticaOblique()
                : pw.Font.helvetica(),
        fontSize: size,
        color: color ?? PdfColors.black,
      );

  static Future<Uint8List> generate(Invoice inv) async {
    final doc = pw.Document(
      title: 'Tax Invoice #${inv.invoiceNo}',
      author: AppConstants.shopName,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        build: (ctx) => [
          _buildTitle(),
          _buildTopHeader(inv),
          _buildItemsTable(inv),
          _buildAmountInWords(inv),
          _buildTaxTable(inv),
          _buildTaxAmountInWords(inv),
          _buildFooter(inv),
          _buildPageFooter(ctx),
        ],
      ),
    );

    return doc.save();
  }

  // ── 1. Title ────────────────────────────────────────────────────
  static pw.Widget _buildTitle() {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text('Tax Invoice', style: _style(size: 12, bold: true)),
    );
  }

  // ── 2. Top Header ───────────────────────────────────────────────
  static pw.Widget _buildTopHeader(Invoice inv) {
    final dtParsed = DateTime.tryParse(inv.dateTime) ?? DateTime.now();
    final dateStr = DateFormat('dd-MMM-yy').format(dtParsed);

    pw.Widget gridCell(String title, String value, {bool bold = false}) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(3),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: _style(size: 6.5)),
            if (value.isNotEmpty)
              pw.Text(value, style: _style(size: 8, bold: bold)),
          ],
        ),
      );
    }

    return pw.Table(
      border: const pw.TableBorder(
        top: _border,
        left: _border,
        right: _border,
        verticalInside: _border,
        bottom: pw.BorderSide.none, // Items Table has top border
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            // Left Side
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(AppConstants.shopName,
                          style: _style(size: 10, bold: true)),
                      pw.Text(AppConstants.shopAddressSingleLine,
                          style: _style(size: 8)),
                      pw.Text('GSTIN/UIN: ${AppConstants.gstin}',
                          style: _style(size: 8)),
                      pw.Text(
                          'State Name : ${AppConstants.state}, Code: ${AppConstants.stateCode}',
                          style: _style(size: 8)),
                      pw.Text('Contact : +91-${AppConstants.phone}',
                          style: _style(size: 8)),
                      pw.Text('E-Mail : ${AppConstants.email}',
                          style: _style(size: 8)),
                    ],
                  ),
                ),
                pw.Container(height: 0.5, color: _borderColor),
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Consignee (Ship to)', style: _style(size: 7)),
                      pw.Text(inv.customerName,
                          style: _style(size: 9, bold: true)),
                      pw.Text(inv.customerAddress, style: _style(size: 8)),
                      if (inv.customerPhone.isNotEmpty)
                        pw.Text('Contact : ${inv.customerPhone}',
                            style: _style(size: 8)),
                      if (inv.customerDistrict.isNotEmpty)
                        pw.Text('District: ${inv.customerDistrict}',
                            style: _style(size: 8)),
                      if (inv.customerPincode.isNotEmpty)
                        pw.Text('PIN Code: ${inv.customerPincode}',
                            style: _style(size: 8)),
                      if (inv.customerGSTIN.isNotEmpty)
                        pw.Text('GSTIN/UIN: ${inv.customerGSTIN}',
                            style: _style(size: 8)),
                      if (inv.customerState.isNotEmpty)
                        pw.Text('State Name: ${inv.customerState}',
                            style: _style(size: 8)),
                    ],
                  ),
                ),
                pw.Container(height: 0.5, color: _borderColor),
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Buyer (Bill to)', style: _style(size: 7)),
                      pw.Text(inv.customerName,
                          style: _style(size: 9, bold: true)),
                      pw.Text(inv.customerAddress, style: _style(size: 8)),
                      if (inv.customerPhone.isNotEmpty)
                        pw.Text('Contact : ${inv.customerPhone}',
                            style: _style(size: 8)),
                      if (inv.customerDistrict.isNotEmpty)
                        pw.Text('District: ${inv.customerDistrict}',
                            style: _style(size: 8)),
                      if (inv.customerPincode.isNotEmpty)
                        pw.Text('PIN Code: ${inv.customerPincode}',
                            style: _style(size: 8)),
                      if (inv.customerGSTIN.isNotEmpty)
                        pw.Text('GSTIN/UIN: ${inv.customerGSTIN}',
                            style: _style(size: 8)),
                      if (inv.customerState.isNotEmpty)
                        pw.Text('State Name: ${inv.customerState}',
                            style: _style(size: 8)),
                    ],
                  ),
                ),
              ],
            ),
            // Right Side
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Table(
                  border: const pw.TableBorder(
                    bottom: _border,
                    horizontalInside: _border,
                    verticalInside: _border,
                  ),
                  children: [
                    pw.TableRow(children: [
                      gridCell('Invoice No.', inv.invoiceNo.toString(), bold: true),
                      gridCell('Dated', dateStr, bold: true)
                    ]),
                    pw.TableRow(children: [
                      gridCell('Delivery Note', ''),
                      gridCell('Mode/Terms of Payment', '')
                    ]),
                    pw.TableRow(children: [
                      gridCell('Reference No. & Date.', '', bold: true),
                      gridCell('Other References', '')
                    ]),
                    pw.TableRow(children: [
                      gridCell('Buyer\'s Order No.', ''),
                      gridCell('Dated', '')
                    ]),
                    pw.TableRow(children: [
                      gridCell('Dispatch Doc No.', ''),
                      gridCell('Delivery Note Date', '')
                    ]),
                    pw.TableRow(children: [
                      gridCell('Dispatched through', ''),
                      gridCell('Destination', '')
                    ]),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(3),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Terms of Delivery', style: _style(size: 6.5)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── 3. Items Table ──────────────────────────────────────────────
  static pw.Widget _buildItemsTable(Invoice inv) {
    pw.Widget headerCell(String text) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: _border)),
        child: pw.Text(
          text,
          style: _style(size: 7, bold: true),
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    pw.Widget itemCell(String text,
        {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
        alignment: align == pw.TextAlign.right
            ? pw.Alignment.topRight
            : align == pw.TextAlign.center
                ? pw.Alignment.topCenter
                : pw.Alignment.topLeft,
        child: pw.Text(text, style: _style(size: 8, bold: bold)),
      );
    }

    final rows = <pw.TableRow>[
      pw.TableRow(
        children: [
          headerCell('SI\nNo.'),
          headerCell('Description of Goods'),
          headerCell('HSN/SAC'),
          headerCell('Quantity'),
          headerCell('Rate\n(Incl. of Tax)'),
          headerCell('Rate'),
          headerCell('per'),
          headerCell('Disc. %'),
          headerCell('Amount'),
        ],
      )
    ];

    for (int i = 0; i < inv.items.length; i++) {
      final item = inv.items[i];
      final itemRate = item.taxableValue / item.quantity;
      final descRows = <pw.Widget>[
        pw.Text(item.description, style: _style(size: 8, bold: true)),
      ];

      final snLines = item.serialNumbers
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      for (final sn in snLines) {
        descRows.add(pw.Text(sn, style: _style(size: 7, italic: true)));
      }

      rows.add(pw.TableRow(
        children: [
          itemCell('${item.slNo}', align: pw.TextAlign.center),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: descRows,
            ),
          ),
          itemCell(item.hsnCode, align: pw.TextAlign.center),
          itemCell('${item.quantity} Nos', align: pw.TextAlign.center),
          itemCell(Helpers.formatCurrency(item.rateInclGST),
              align: pw.TextAlign.right),
          itemCell(Helpers.formatCurrency(itemRate),
              align: pw.TextAlign.right),
          itemCell('Nos', align: pw.TextAlign.center),
          itemCell(item.discountPercent > 0 ? '${item.discountPercent}%' : '',
              align: pw.TextAlign.center),
          itemCell(Helpers.formatCurrency(item.amount),
              align: pw.TextAlign.right, bold: true),
        ],
      ));
    }

    // Add SGST and CGST line items
    if (inv.totalSGST > 0) {
      rows.add(pw.TableRow(
        children: [
          itemCell(''),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            alignment: pw.Alignment.centerRight,
            child: pw.Text('SGST 9%',
                style: _style(size: 8, bold: true, italic: true)),
          ),
          itemCell(''),
          itemCell(''),
          itemCell(''),
          itemCell(''),
          itemCell(''),
          itemCell(''),
          itemCell(Helpers.formatCurrency(inv.totalSGST),
              align: pw.TextAlign.right, bold: true),
        ],
      ));
    }

    if (inv.totalCGST > 0) {
      rows.add(pw.TableRow(
        children: [
          itemCell(''),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            alignment: pw.Alignment.centerRight,
            child: pw.Text('CGST 9%',
                style: _style(size: 8, bold: true, italic: true)),
          ),
          itemCell(''),
          itemCell(''),
          itemCell(''),
          itemCell(''),
          itemCell(''),
          itemCell(''),
          itemCell(Helpers.formatCurrency(inv.totalCGST),
              align: pw.TextAlign.right, bold: true),
        ],
      ));
    }

    // Padding row
    rows.add(pw.TableRow(
      children: List.generate(9, (index) => pw.Container(height: 10)),
    ));

    // Total row
    pw.Widget totalCell(String text,
        {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
        decoration: const pw.BoxDecoration(border: pw.Border(top: _border)),
        alignment: align == pw.TextAlign.right
            ? pw.Alignment.centerRight
            : align == pw.TextAlign.center
                ? pw.Alignment.center
                : pw.Alignment.centerLeft,
        child: pw.Text(text, style: _style(size: 8, bold: bold)),
      );
    }

    rows.add(pw.TableRow(
      children: [
        totalCell(''),
        totalCell('Total', align: pw.TextAlign.right),
        totalCell(''),
        totalCell('${inv.totalQuantity} Nos',
            align: pw.TextAlign.center, bold: true),
        totalCell(''),
        totalCell(''),
        totalCell(''),
        totalCell(''),
        totalCell('Rs. ${Helpers.formatCurrency(inv.grandTotal)}',
            align: pw.TextAlign.right, bold: true),
      ],
    ));

    return pw.Table(
      border: const pw.TableBorder(
        top: _border,
        bottom: pw.BorderSide.none,
        left: _border,
        right: _border,
        verticalInside: _border,
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(22),
        1: pw.FlexColumnWidth(3),
        2: pw.FixedColumnWidth(40),
        3: pw.FixedColumnWidth(38),
        4: pw.FixedColumnWidth(48),
        5: pw.FixedColumnWidth(45),
        6: pw.FixedColumnWidth(22),
        7: pw.FixedColumnWidth(30),
        8: pw.FixedColumnWidth(55),
      },
      children: rows,
    );
  }

  // ── 4. Amount Chargeable In Words ─────────────────────────────────
  static pw.Widget _buildAmountInWords(Invoice inv) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: _border,
          left: _border,
          right: _border,
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                      text: 'Amount Chargeable (in words)\n',
                      style: _style(size: 7)),
                  pw.TextSpan(
                      text: 'INR ${NumberToWords.convert(inv.grandTotal)}',
                      style: _style(size: 8, bold: true)),
                ],
              ),
            ),
          ),
          pw.Text('E. & O.E', style: _style(size: 8, italic: true)),
        ],
      ),
    );
  }

  // ── 5. Tax Table ────────────────────────────────────────────────
  static pw.Widget _buildTaxTable(Invoice inv) {
    pw.Widget taxCell(String text,
        {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
        alignment: align == pw.TextAlign.right
            ? pw.Alignment.centerRight
            : align == pw.TextAlign.center
                ? pw.Alignment.center
                : pw.Alignment.centerLeft,
        child: pw.Text(text, style: _style(size: 7.5, bold: bold)),
      );
    }

    final hsnMap = <String, Map<String, double>>{};
    for (var item in inv.items) {
      if (!hsnMap.containsKey(item.hsnCode)) {
        hsnMap[item.hsnCode] = {'taxable': 0, 'cgst': 0, 'sgst': 0};
      }
      hsnMap[item.hsnCode]!['taxable'] =
          (hsnMap[item.hsnCode]!['taxable'] ?? 0) + item.taxableValue;
      hsnMap[item.hsnCode]!['cgst'] =
          (hsnMap[item.hsnCode]!['cgst'] ?? 0) + item.cgst;
      hsnMap[item.hsnCode]!['sgst'] =
          (hsnMap[item.hsnCode]!['sgst'] ?? 0) + item.sgst;
    }

    final rows = <pw.TableRow>[
      pw.TableRow(
        children: [
          taxCell('HSN/SAC', bold: true, align: pw.TextAlign.center),
          taxCell('Taxable\nValue', bold: true, align: pw.TextAlign.center),
          taxCell('CGST\nRate', bold: true, align: pw.TextAlign.center),
          taxCell('CGST\nAmount', bold: true, align: pw.TextAlign.center),
          taxCell('SGST/UTGST\nRate', bold: true, align: pw.TextAlign.center),
          taxCell('SGST/UTGST\nAmount',
              bold: true, align: pw.TextAlign.center),
          taxCell('Total\nTax Amount', bold: true, align: pw.TextAlign.center),
        ],
      )
    ];

    for (var entry in hsnMap.entries) {
      final data = entry.value;
      final totalTax = data['cgst']! + data['sgst']!;
      rows.add(pw.TableRow(
        children: [
          taxCell(entry.key),
          taxCell(Helpers.formatCurrency(data['taxable']!),
              align: pw.TextAlign.right),
          taxCell('9%', align: pw.TextAlign.right),
          taxCell(Helpers.formatCurrency(data['cgst']!),
              align: pw.TextAlign.right),
          taxCell('9%', align: pw.TextAlign.right),
          taxCell(Helpers.formatCurrency(data['sgst']!),
              align: pw.TextAlign.right),
          taxCell(Helpers.formatCurrency(totalTax), align: pw.TextAlign.right),
        ],
      ));
    }

    rows.add(pw.TableRow(
      children: [
        taxCell('Total', bold: true, align: pw.TextAlign.right),
        taxCell(Helpers.formatCurrency(inv.totalTaxableValue),
            bold: true, align: pw.TextAlign.right),
        taxCell(''),
        taxCell(Helpers.formatCurrency(inv.totalCGST),
            bold: true, align: pw.TextAlign.right),
        taxCell(''),
        taxCell(Helpers.formatCurrency(inv.totalSGST),
            bold: true, align: pw.TextAlign.right),
        taxCell(Helpers.formatCurrency(inv.totalCGST + inv.totalSGST),
            bold: true, align: pw.TextAlign.right),
      ],
    ));

    return pw.Table(
      border: const pw.TableBorder(
        top: _border,
        left: _border,
        right: _border,
        horizontalInside: _border,
        verticalInside: _border,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1.5),
        6: pw.FlexColumnWidth(1.5),
      },
      children: rows,
    );
  }

  // ── 6. Tax Amount In Words ──────────────────────────────────────
  static pw.Widget _buildTaxAmountInWords(Invoice inv) {
    return pw.Container(
      width: double.infinity,
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: _border,
          left: _border,
          right: _border,
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
                text: 'Tax Amount (in words) : ', style: _style(size: 7.5)),
            pw.TextSpan(
                text:
                    'INR ${NumberToWords.convert(inv.totalCGST + inv.totalSGST)}',
                style: _style(size: 8, bold: true)),
          ],
        ),
      ),
    );
  }

  // ── 7. Footer ───────────────────────────────────────────────────
  static pw.Widget _buildFooter(Invoice inv) {
    pw.Widget bankRow(String key, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(flex: 3, child: pw.Text(key, style: _style(size: 7.5))),
            pw.Expanded(
                flex: 7,
                child:
                    pw.Text(': $value', style: _style(size: 7.5, bold: true))),
          ],
        ),
      );
    }

    return pw.Table(
      border: const pw.TableBorder(
        top: _border,
        left: _border,
        right: _border,
        bottom: _border,
        verticalInside: _border,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.SizedBox(
                      height: 48), // Push down to match Bank details height
                  pw.Text('Declaration', style: _style(size: 7, italic: true)),
                  pw.SizedBox(height: 2),
                  pw.Text(AppConstants.declaration, style: _style(size: 8)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Company's Bank Details", style: _style(size: 7)),
                      bankRow(
                          "A/c Holder's Name", AppConstants.bankAccountHolder),
                      bankRow("Bank Name", AppConstants.bankName),
                      bankRow("A/c No.", AppConstants.bankAccount),
                      bankRow("IFSC Code", AppConstants.bankIfsc),
                      bankRow("Branch", AppConstants.bankBranch),
                    ],
                  ),
                ),
                pw.Container(height: 0.5, color: _borderColor),
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('for ${AppConstants.shopName}',
                          style: _style(size: 8, bold: true)),
                      pw.SizedBox(height: 30), // Spacing for signature
                      pw.Text('Authorised Signatory', style: _style(size: 8)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── Page Footer (Generated Notice) ──────────────────────────────
  static pw.Widget _buildPageFooter(pw.Context ctx) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Text(
        'This is a Computer Generated Invoice',
        style: _style(size: 7),
      ),
    );
  }
}
