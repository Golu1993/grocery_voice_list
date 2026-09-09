import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/grocery_field.dart';
import '../models/order_item.dart';
import '../utils/unit_converter.dart';

class GroceryPdfService {
  GroceryPdfService._();

  static const String appDownloadUrl =
      'https://play.google.com/store/apps/details?id=com.niviclouds.groceryvoicelist';

  static const _regularFontPath = 'assets/fonts/NotoSans-Regular.ttf';
  static const _boldFontPath = 'assets/fonts/NotoSans-Bold.ttf';
  static const _devanagariFontPath = 'assets/fonts/NotoSansDevanagari.ttf';

  static Future<_GroceryPdfFonts>? _fonts;

  static String fileNameFor(OrderItem order) =>
      'vocart-list-${order.orderId}.pdf';

  static Future<Uint8List> generate(
    OrderItem order, {
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final fonts = await (_fonts ??= _loadFonts());
    return _build(order, fonts: fonts, pageFormat: pageFormat);
  }

  static Future<_GroceryPdfFonts> _loadFonts() async {
    final regular = await rootBundle.load(_regularFontPath);
    final bold = await rootBundle.load(_boldFontPath);
    final devanagari = await rootBundle.load(_devanagariFontPath);
    return _GroceryPdfFonts(
      regular: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
      devanagari: pw.Font.ttf(devanagari),
    );
  }

  static Future<Uint8List> _build(
    OrderItem order, {
    required _GroceryPdfFonts fonts,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final document = pw.Document(
      title: 'Vocart List',
      author: '',
      creator: 'Vocart',
      version: PdfVersion.pdf_1_5,
      compress: true,
    );
    final completed = order.itemList
        .where((item) => item.isChecked == true)
        .length;
    final remaining = order.itemList.length - completed;
    final primary = PdfColor.fromHex('#1478ED');
    final primaryContainer = PdfColor.fromHex('#E8F2FF');
    final textColor = PdfColor.fromHex('#17212B');
    final muted = PdfColor.fromHex('#687582');
    final divider = PdfColor.fromHex('#DDE4EA');

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.fromLTRB(42, 42, 42, 38),
        theme: pw.ThemeData.withFont(
          base: fonts.regular,
          bold: fonts.bold,
          fontFallback: [fonts.devanagari],
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: divider, width: .7)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'Created with Vocart | ',
                    style: pw.TextStyle(fontSize: 8, color: muted),
                  ),
                  pw.UrlLink(
                    destination: appDownloadUrl,
                    child: pw.Text(
                      'Get the app',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: primary,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: muted),
              ),
            ],
          ),
        ),
        build: (_) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'VOCART',
                      style: pw.TextStyle(
                        color: primary,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: .8,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Vocart List',
                      style: pw.TextStyle(
                        color: textColor,
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 18),
              pw.Text(
                order.time,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontSize: 9, color: muted),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Container(height: 2, color: primary),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            decoration: pw.BoxDecoration(
              color: primaryContainer,
              borderRadius: pw.BorderRadius.circular(7),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${order.itemList.length} ${order.itemList.length == 1 ? 'item' : 'items'}',
                  style: pw.TextStyle(
                    color: primary,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '$completed completed  •  $remaining remaining',
                  style: pw.TextStyle(
                    color: primary,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildItemsTable(
            order.itemList,
            textColor: textColor,
            muted: muted,
            divider: divider,
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _buildItemsTable(
    List<GroceryField> items, {
    required PdfColor textColor,
    required PdfColor muted,
    required PdfColor divider,
  }) {
    return pw.Table(
      columnWidths: const {0: pw.FlexColumnWidth(), 1: pw.FixedColumnWidth(92)},
      children: [
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: divider)),
          ),
          children: [
            _headerCell('ITEM', muted),
            _headerCell('QUANTITY', muted, alignRight: true),
          ],
        ),
        ...items.map(
          (item) => pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: divider, width: .7),
              ),
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text(
                  item.name,
                  style: pw.TextStyle(
                    color: item.isChecked == true ? muted : textColor,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    decoration: item.isChecked == true
                        ? pw.TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text(
                  UnitConverter.formatQuantity(item.quantity, item.unit),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 10, color: muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _headerCell(
    String label,
    PdfColor color, {
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Text(
        label,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class _GroceryPdfFonts {
  const _GroceryPdfFonts({
    required this.regular,
    required this.bold,
    required this.devanagari,
  });

  final pw.Font regular;
  final pw.Font bold;
  final pw.Font devanagari;
}
