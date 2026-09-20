import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/date_format.dart';
import '../../../core/utils/money_format.dart';
import '../data/pagos_models.dart';
import '../presentation/comprobante_printing.dart';

enum ComprobanteShareTarget {
  whatsappBusiness,
}

class ComprobanteShareService {
  const ComprobanteShareService();

  static const _channel = MethodChannel('credinexo/share');

  Future<File> buildComprobantePdfFile({
    required ComprobanteRender comprobante,
    required int pagoId,
    required PagoContexto contexto,
  }) async {
    final bytes = await buildComprobantePdfBytes(
      comprobante,
      ticket58PageFormat,
    );
    final directory = await getTemporaryDirectory();
    final referencia = _safeFilePart(contexto.credito.referenciaVisual);
    final timestamp = _fileTimestamp(DateTime.now());
    final fileName = referencia.isEmpty
        ? 'comprobante_pago_${timestamp}_$pagoId.pdf'
        : 'comprobante_pago_${timestamp}_$referencia.pdf';
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<void> shareComprobante({
    required ComprobanteRender comprobante,
    required int pagoId,
    required double monto,
    required PagoContexto contexto,
    required ComprobanteShareTarget target,
  }) async {
    final file = await buildComprobantePdfFile(
      comprobante: comprobante,
      pagoId: pagoId,
      contexto: contexto,
    );
    final message =
        _buildMessage(monto: monto, contexto: contexto, target: target);
    if (!Platform.isAndroid) {
      throw PlatformException(
        code: 'WHATSAPP_BUSINESS_NOT_INSTALLED',
        message: 'WhatsApp Business solo esta disponible en Android.',
      );
    }
    await _channel.invokeMethod<void>('sharePdfToWhatsAppBusiness', {
      'path': file.path,
      'message': message,
    });
  }
}

String _buildMessage({
  required double monto,
  required PagoContexto contexto,
  required ComprobanteShareTarget target,
}) {
  final cliente = contexto.credito.cliente.nombreCompleto.trim();
  final fecha = dateFormat(DateTime.now().toIso8601String());
  final appHint = switch (target) {
    ComprobanteShareTarget.whatsappBusiness =>
      'Seleccione WhatsApp Business para enviarlo.',
  };
  return [
    'Hola, le compartimos su comprobante de pago de CrediNexo.',
    '',
    if (cliente.isNotEmpty) 'Cliente: $cliente',
    'Monto pagado: ${moneyFormat(monto)}',
    'Fecha: $fecha',
    '',
    'Adjunto encontrara su comprobante.',
    if (appHint.isNotEmpty) appHint,
  ].join('\n');
}

String _fileTimestamp(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$year-$month-${day}_$hour$minute';
}

String _safeFilePart(String value) {
  final buffer = StringBuffer();
  var previousWasSeparator = false;
  for (final codeUnit in value.trim().codeUnits) {
    final isNumber = codeUnit >= 48 && codeUnit <= 57;
    final isUppercase = codeUnit >= 65 && codeUnit <= 90;
    final isLowercase = codeUnit >= 97 && codeUnit <= 122;
    final isAllowedSymbol = codeUnit == 45 || codeUnit == 95;
    final isAllowed = isNumber || isUppercase || isLowercase || isAllowedSymbol;
    if (isAllowed) {
      buffer.writeCharCode(codeUnit);
      previousWasSeparator = false;
      continue;
    }
    if (!previousWasSeparator) {
      buffer.write('_');
      previousWasSeparator = true;
    }
  }
  return buffer.toString().replaceAll('_', ' ').trim().replaceAll(' ', '_');
}
