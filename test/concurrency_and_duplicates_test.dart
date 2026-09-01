import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:doc_intelligence/app/controllers/client_form_controller.dart';
import 'package:doc_intelligence/app/core/errors/app_exceptions.dart';
import 'package:doc_intelligence/app/repository/mock_client_repository.dart';
import 'package:doc_intelligence/app/repository/mock_document_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Concorrência e Validação de Duplicatas', () {
    late MockDocumentRepository docRepo;
    late MockClientRepository clientRepo;
    late ClientFormController controller;

    setUp(() {
      docRepo = MockDocumentRepository();
      clientRepo = MockClientRepository();
      controller = ClientFormController(
        clientRepository: clientRepo,
        documentRepository: docRepo,
      );
    });

    test('Detecção de Hash SHA-256 idêntico para evitar duplicatas na fila', () {
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final expectedHash = sha256.convert(sampleBytes).toString();

      final calculated = controller.calculateFileHash(
        sampleBytes,
        'procuracao.pdf',
        5,
      );

      expect(calculated, equals(expectedHash));
    });

    test('Identifica documento duplicado existente nos documentos do cliente', () async {
      final docs = await docRepo.getDocumentsByClientId('1');
      controller.documents.assignAll(docs);

      // Adiciona item com mesmo nome e tamanho de um documento já existente
      final existing = docs.first;
      controller.addFilesToQueue([
        DocumentUploadItem(
          fileName: existing.originalName,
          fileSizeBytes: existing.fileSizeBytes,
        ),
      ]);

      expect(controller.uploadQueue.length, equals(1));
      expect(controller.uploadQueue.first.isDuplicate, isTrue);
      expect(controller.hasDuplicatesInQueue, isTrue);
    });

    test('Lança ConflictException (HTTP 409) quando o documento foi atualizado por outro usuário', () async {
      final docs = await docRepo.getDocumentsByClientId('1');
      final doc = docs.first;

      // Ativa simulação de concorrência no mock
      docRepo.simulateConflictOnNextUpdate = true;

      expect(
        () async => await docRepo.updateDocument(doc),
        throwsA(isA<ConflictException>()),
      );
    });

    test('Permite múltiplos documentos com a mesma tipologia para o mesmo cliente', () async {
      final docs = await docRepo.getDocumentsByClientId('1');
      controller.documents.assignAll(docs);
      controller.selectDocument(docs.first); // doc-1 é 'Contrato'

      // Seleciona outro documento e define como 'Contrato' sem restrição
      controller.selectedDocument.value = docs[1];
      controller.onDocumentTypeChanged('Contrato');

      expect(controller.selectedDocumentType.value, equals('Contrato'));
    });
  });
}
