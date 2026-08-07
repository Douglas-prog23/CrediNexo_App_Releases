import 'dart:async';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/utils/date_format.dart';
import '../../../core/utils/money_format.dart';
import '../data/pagos_models.dart';

const ticket58PageFormat = PdfPageFormat(
  58 * PdfPageFormat.mm,
  420 * PdfPageFormat.mm,
  marginAll: 0,
);

const _pdfTimeout = Duration(seconds: 15);

Future<void> printComprobanteRender(
  ComprobanteRender comprobante, {
  required int pagoId,
}) {
  return Printing.layoutPdf(
    name: 'comprobante_$pagoId.pdf',
    format: ticket58PageFormat,
    dynamicLayout: false,
    forceCustomPrintPaper: true,
    onLayout: (_) => buildComprobantePdfBytes(comprobante, ticket58PageFormat),
  );
}

Future<Uint8List> buildComprobantePdfBytes(
  ComprobanteRender comprobante,
  PdfPageFormat format,
) async {
  final html = comprobante.html?.trim();
  if (html != null && html.isNotEmpty) {
    try {
      // ignore: deprecated_member_use
      return await Printing.convertHtml(
        html: _withThermalTicketCss(html),
        format: format,
      ).timeout(_pdfTimeout);
    } catch (_) {
      if (comprobante.snapshot == null) rethrow;
    }
  }
  return _buildSnapshotPdf(comprobante);
}

Future<Uint8List> _buildSnapshotPdf(ComprobanteRender comprobante) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: ticket58PageFormat,
      margin: const pw.EdgeInsets.all(8),
      build: (_) => [
        pw.Text(
          'Comprobante de pago',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        ..._buildPdfContent(comprobante),
      ],
    ),
  );
  return doc.save();
}

List<pw.Widget> _buildPdfContent(ComprobanteRender comprobante) {
  final rows = _snapshotRows(comprobante.snapshot);
  return rows
      .map(
        (row) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 78,
                child: pw.Text(
                  row.$1,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(row.$2, style: const pw.TextStyle(fontSize: 8)),
              ),
            ],
          ),
        ),
      )
      .toList();
}

List<(String, String)> _snapshotRows(Map<String, dynamic>? snapshot) {
  if (snapshot == null) return const [];
  final pago = snapshot['pago'] is Map<String, dynamic>
      ? snapshot['pago'] as Map<String, dynamic>
      : const <String, dynamic>{};
  final cliente = snapshot['cliente'] is Map<String, dynamic>
      ? snapshot['cliente'] as Map<String, dynamic>
      : const <String, dynamic>{};
  final credito = snapshot['credito'] is Map<String, dynamic>
      ? snapshot['credito'] as Map<String, dynamic>
      : const <String, dynamic>{};
  final aplicacion = snapshot['aplicacion'] is Map<String, dynamic>
      ? snapshot['aplicacion'] as Map<String, dynamic>
      : const <String, dynamic>{};

  return [
    ('Recibo', '${pago['numeroRecibo'] ?? pago['id'] ?? '-'}'),
    (
      'Fecha',
      dateFormat('${pago['fechaPago'] ?? pago['fechaRegistro'] ?? ''}'),
    ),
    ('Cliente', '${cliente['codigo'] ?? ''} ${cliente['nombre'] ?? ''}'.trim()),
    ('Credito', '${credito['numero'] ?? credito['id'] ?? '-'}'),
    ('Monto pagado', moneyFormat(_asDouble(pago['monto']))),
    ('Medio de pago', '${pago['medioPago'] ?? '-'}'),
    ('Saldo antes', moneyFormat(_asDouble(credito['saldoAntes']))),
    ('Saldo despues', moneyFormat(_asDouble(credito['saldoDespues']))),
    (
      'Cuotas pagadas',
      '${aplicacion['cuotasPagadasTexto'] ?? aplicacion['cuotasPagadasDecimal'] ?? '-'}',
    ),
    ('Cuotas pendientes', '${aplicacion['cuotasPendientes'] ?? '-'}'),
  ];
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

String _withThermalTicketCss(String html) {
  const thermalCss = '''
<style id="credinexo-thermal-ticket">
  @page { size: 58mm auto; margin: 0; }
  html, body {
    width: 58mm !important;
    max-width: 58mm !important;
    min-width: 58mm !important;
    margin: 0 !important;
    padding: 0 !important;
    background: #fff !important;
    overflow: visible !important;
  }
  body {
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }
  .page {
    width: 58mm !important;
    max-width: 58mm !important;
    min-width: 58mm !important;
    margin: 0 !important;
    padding: 2mm !important;
    border: 0 !important;
    box-shadow: none !important;
    background: #fff !important;
  }
  .ticket {
    width: 100% !important;
    max-width: 54mm !important;
    margin: 0 auto !important;
  }
  img {
    max-width: 100% !important;
    height: auto !important;
  }
</style>
''';
  final headCloseIndex = html.toLowerCase().indexOf('</head>');
  if (headCloseIndex >= 0) {
    return '${html.substring(0, headCloseIndex)}$thermalCss${html.substring(headCloseIndex)}';
  }
  return '$thermalCss$html';
}
