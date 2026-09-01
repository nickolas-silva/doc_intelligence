import 'package:doc_intelligence/app/core/utils/mock_document_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockDocumentGenerator tests', () {
    test('generates legal PDF bytes without font encoding errors', () {
      final bytes = MockDocumentGenerator.generateLegalPdf(
        title: 'Contrato de Prestação de Serviços Advocatícios',
        clientName: 'João Fictício da Silva',
        docType: 'Contrato',
        date: '10/02/2024',
        extraClause: 'Assessoria jurídica contenciosa e consultiva.',
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
      // PDF magic number %PDF
      expect(String.fromCharCodes(bytes.take(4)), equals('%PDF'));
    });
  });
}
