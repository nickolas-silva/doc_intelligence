import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Utilitário para geração de documentos PDF e imagens em memória
/// para simulação de alta fidelidade no ambiente de mock.
abstract class MockDocumentGenerator {
  /// Gera um PDF jurídico fictício completo e elegante em memória
  static Uint8List generateLegalPdf({
    required String title,
    required String clientName,
    required String docType,
    required String date,
    String? extraClause,
  }) {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;

    // Fontes padrão suportadas
    final fontHeader = PdfStandardFont(
      PdfFontFamily.helvetica,
      13,
      style: PdfFontStyle.bold,
    );
    final fontSubtitle = PdfStandardFont(
      PdfFontFamily.helvetica,
      9,
      style: PdfFontStyle.italic,
    );
    final fontTitle = PdfStandardFont(
      PdfFontFamily.helvetica,
      12,
      style: PdfFontStyle.bold,
    );
    final fontBody = PdfStandardFont(PdfFontFamily.helvetica, 10);

    // Timbre Institucional (usando caracteres ASCII seguros)
    graphics.drawString(
      'DOC INTELLIGENCE - ADVOCACIA E CONSULTORIA JURIDICA',
      fontHeader,
      brush: PdfSolidBrush(PdfColor(180, 140, 50)),
      bounds: const Rect.fromLTWH(0, 0, 500, 20),
    );

    graphics.drawString(
      'Documento Ficticio para Demonstracao de Inteligencia Documental - Lei 13.709/2018',
      fontSubtitle,
      brush: PdfSolidBrush(PdfColor(100, 100, 100)),
      bounds: const Rect.fromLTWH(0, 22, 500, 16),
    );

    // Linha dourada divisória desenhada com Pen (vetorial)
    graphics.drawLine(
      PdfPen(PdfColor(212, 168, 67), width: 1.5),
      const Offset(0, 42),
      const Offset(500, 42),
    );

    // Título do Instrumento
    final cleanTitle = _sanitizePdfText(title.toUpperCase());
    graphics.drawString(
      cleanTitle,
      fontTitle,
      brush: PdfSolidBrush(PdfColor(20, 20, 20)),
      bounds: const Rect.fromLTWH(0, 58, 500, 22),
    );

    final cleanClient = _sanitizePdfText(clientName);
    final cleanType = _sanitizePdfText(docType);
    final cleanClause = _sanitizePdfText(
      extraClause ??
          'As partes declaram que todas as informacoes foram conferidas pelo sistema de extracao inteligente, atestando conformidade com as regras processuais e de sigilo profissional.',
    );

    final text = '''
TIPO DE DOCUMENTO: $cleanType
TITULAR / PARTE: $cleanClient
DATA DE REGISTRO: $date
CODIGO DE AUTENTICIDADE: DOC-INTEL-${DateTime.now().year}-${(title.hashCode.abs() % 90000) + 10000}

------------------------------------------------------------------------------------------------------

CLAUSULA PRIMEIRA - DO OBJETO E QUALIFICACAO
Pelo presente instrumento, formaliza-se o registro e a indexacao documental de $cleanType em favor de $cleanClient, para fins de analise pericial e processamento automatizado perante o departamento juridico.

CLAUSULA SEGUNDA - DA CONFERENCIA AUTOMATIZADA
$cleanClause

CLAUSULA TERCEIRA - DA VALIDADE DIGITAL
O presente documento foi emitido e catalogado eletronicamente, integrando o dossie digital com garantia de integridade e temporalidade dos dados processados.

Brasilia - DF, $date.


____________________________________________________________
$cleanClient
Titular / Outorgante Qualificado
''';

    final textElement = PdfTextElement(
      text: text,
      font: fontBody,
      brush: PdfSolidBrush(PdfColor(30, 30, 30)),
    );

    textElement.draw(
      page: page,
      bounds: const Rect.fromLTWH(0, 90, 500, 630),
    );

    final List<int> bytes = document.saveSync();
    document.dispose();
    return Uint8List.fromList(bytes);
  }

  /// Sanitiza texto para garantir compatibilidade estrita com a codificação Standard WinAnsi / Latin1
  static String _sanitizePdfText(String input) {
    var result = input;
    const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    const withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    // Remove qualquer outro caractere especial fora da tabela ASCII básica
    result = result.replaceAll('•', '-');
    result = result.replaceAll('—', '-');
    result = result.replaceAll('–', '-');
    result = result.replaceAll('─', '-');
    result = result.replaceAll(RegExp(r'[^\x20-\x7E\r\n\t]'), '');
    return result;
  }

  /// Gera imagem PNG fictícia (ex: comprovante / CNH) em base64/bytes
  static Uint8List generateSampleImageBytes({
    required String label,
    required String clientName,
  }) {
    const base64Png =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    return base64Decode(base64Png);
  }
}
