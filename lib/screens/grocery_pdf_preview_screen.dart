import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/order_item.dart';
import '../services/grocery_pdf_service.dart';

class GroceryPdfPreviewScreen extends StatefulWidget {
  const GroceryPdfPreviewScreen({super.key, required this.order});

  final OrderItem order;

  @override
  State<GroceryPdfPreviewScreen> createState() =>
      _GroceryPdfPreviewScreenState();
}

class _GroceryPdfPreviewScreenState extends State<GroceryPdfPreviewScreen> {
  bool _isSharing = false;

  Future<void> _sharePdf() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final bytes = await GroceryPdfService.generate(widget.order);
      if (!mounted) return;
      final renderBox = context.findRenderObject() as RenderBox?;
      final bounds = renderBox == null
          ? null
          : renderBox.localToGlobal(Offset.zero) & renderBox.size;

      await Printing.sharePdf(
        bytes: bytes,
        filename: GroceryPdfService.fileNameFor(widget.order),
        bounds: bounds,
        subject: 'Vocart List',
        body:
            'Shared from Vocart - Voice Grocery List\n'
            'Get the app: ${GroceryPdfService.appDownloadUrl}',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share this PDF. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              GroceryPdfService.fileNameFor(widget.order),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'PDF preview',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: PdfPreview(
        build: (format) =>
            GroceryPdfService.generate(widget.order, pageFormat: format),
        initialPageFormat: PdfPageFormat.a4,
        pdfFileName: GroceryPdfService.fileNameFor(widget.order),
        allowPrinting: false,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        useActions: false,
        maxPageWidth: 700,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        onError: (_, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not create the PDF preview.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.error),
            ),
          ),
        ),
        scrollViewDecoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
        ),
      ),
      bottomNavigationBar: Material(
        color: colors.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSharing ? null : _sharePdf,
                icon: _isSharing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary.withValues(alpha: 0.8),
                        ),
                      )
                    : const Icon(Icons.share_rounded),
                label: Text(_isSharing ? 'Preparing…' : 'Share PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  disabledBackgroundColor: colors.primary.withValues(
                    alpha: 0.55,
                  ),
                  disabledForegroundColor: colors.onPrimary.withValues(
                    alpha: 0.8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
