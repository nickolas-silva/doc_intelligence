import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/document_model.dart';
import 'document_repository.dart';

/// Implementação Mock do repositório de documentos com dados fictícios,
/// suporte a hash de arquivo, detecção de concorrência (HTTP 409 Conflict)
/// e simulação de latência de processamento de IA.
///
/// Não deve importar ou depender do pacote `get`.
class MockDocumentRepository implements DocumentRepository {
  final _uuid = const Uuid();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  static const String defaultPdfAsset = 'assets/mock/desafio.pdf';
  static const String defaultImageUrl =
      'https://dummyimage.com/600x400/000/fff.png&text=Exemplo+de+documento';

  /// Flag para simulação de conflito de concorrência (HTTP 409) no próximo update
  bool simulateConflictOnNextUpdate = false;

  late final List<DocumentModel> _mockDocuments;

  MockDocumentRepository() {
    _initializeMockDocuments();
  }

  void _initializeMockDocuments() {
    _mockDocuments = [
      DocumentModel(
        id: 'doc-1',
        clientId: '1',
        originalName: 'contrato_prestacao_servicos_scan_01.pdf',
        standardizedName: 'CONTRATO_JOAO_28_08_2026.pdf',
        fileType: 'pdf',
        fileSizeBytes: 523953,
        status: DocumentStatus.reviewed,
        assetPath: defaultPdfAsset,
        fileHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        version: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        extractedData: {
          'document_type': 'Contrato',
          'document_date': '10/02/2024',
          'observations': 'Assinatura digital válida reconhecida.',
        },
      ),
      DocumentModel(
        id: 'doc-2',
        clientId: '1',
        originalName: 'procuracao_ad_judicia_et_extra_v1.pdf',
        standardizedName: 'PROCURACAO_JOAO_29_08_2026.pdf',
        fileType: 'pdf',
        fileSizeBytes: 523953,
        status: DocumentStatus.awaitingReview,
        assetPath: defaultPdfAsset,
        fileHash: 'a8b1c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852c999',
        version: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        extractedData: {
          'document_type': 'Procuração',
          'document_date': '15/02/2024',
          'observations': 'Poderes ad judicia e extra concedidos.',
        },
      ),
      DocumentModel(
        id: 'doc-3',
        clientId: '1',
        originalName: 'comprovante_residencia_energia.png',
        standardizedName: 'COMPROVANTE_RESIDENCIA_JOAO_30_08_2026.png',
        fileType: 'png',
        fileSizeBytes: 1024 * 180,
        status: DocumentStatus.pending,
        fileHash: 'b5c2d66298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852d111',
        version: 1,
        previewUrl: defaultImageUrl,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      DocumentModel(
        id: 'doc-4',
        clientId: '1',
        originalName: 'cnh_frente_verso_foto.jpg',
        standardizedName: 'CNH_JOAO_31_08_2026.jpg',
        fileType: 'jpg',
        fileSizeBytes: 1024 * 340,
        status: DocumentStatus.pending,
        fileHash: 'f4d3e77298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852e222',
        version: 1,
        previewUrl: defaultImageUrl,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      DocumentModel(
        id: 'doc-5',
        clientId: '3',
        originalName: 'laudo_pericial_contabil_assinado.pdf',
        standardizedName: 'LAUDO_MEDICO_PERICIAL_CARLOS_26_08_2026.pdf',
        fileType: 'pdf',
        fileSizeBytes: 523953,
        status: DocumentStatus.reviewed,
        assetPath: defaultPdfAsset,
        fileHash: 'c9e4f88298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852f333',
        version: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        extractedData: {
          'document_type': 'Laudo Médico / Pericial',
          'document_date': '15/11/2023',
          'observations': 'Perícia contábil com parecer favorável.',
        },
      ),
    ];
  }

  @override
  Future<List<DocumentModel>> getDocumentsByClientId(String clientId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockDocuments.where((doc) => doc.clientId == clientId).toList();
  }

  @override
  Future<DocumentModel> uploadDocument({
    required String clientId,
    required String fileName,
    required String fileType,
    required int fileSizeBytes,
    Uint8List? bytes,
    String? previewUrl,
    String? assetPath,
    String? fileHash,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final isPdf = fileType.toLowerCase() == 'pdf';
    final fallbackUrl = isPdf ? null : defaultImageUrl;
    final fallbackAsset = isPdf ? defaultPdfAsset : null;

    final now = DateTime.now();
    final newDoc = DocumentModel(
      id: _uuid.v4(),
      clientId: clientId,
      originalName: fileName,
      fileType: fileType,
      fileSizeBytes: fileSizeBytes,
      status: DocumentStatus.pending,
      bytes: bytes,
      assetPath: assetPath ?? fallbackAsset,
      previewUrl: previewUrl ?? fallbackUrl,
      fileHash: fileHash,
      version: 1,
      createdAt: now,
    );

    _mockDocuments.add(newDoc);
    return newDoc;
  }

  @override
  Future<DocumentModel> processDocument(String documentId) async {
    // Simula a latência de processamento de IA
    await Future.delayed(const Duration(seconds: 4));

    final index = _mockDocuments.indexWhere((doc) => doc.id == documentId);
    if (index == -1) {
      throw Exception('Documento não encontrado para processamento.');
    }

    final doc = _mockDocuments[index];
    final inferredType = _inferDocType(doc.originalName);
    final now = DateTime.now();

    final processed = doc.copyWith(
      status: DocumentStatus.awaitingReview, // Vai para aguardando conferência
      version: doc.version + 1,
      updatedAt: now,
      extractedData: {
        'document_type': inferredType,
        'document_date': _dateFormat.format(now),
        'observations':
            'Extração automatizada por IA realizada com sucesso. Revise e confirme os dados.',
      },
    );

    _mockDocuments[index] = processed;
    return processed;
  }

  @override
  Future<DocumentModel> updateDocument(DocumentModel document) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final index = _mockDocuments.indexWhere((doc) => doc.id == document.id);
    if (index == -1) {
      throw Exception('Documento não encontrado para atualização.');
    }

    final existing = _mockDocuments[index];

    // Simulação explícita de concorrência ou detecção de versão desatualizada
    if (simulateConflictOnNextUpdate) {
      simulateConflictOnNextUpdate = false;
      // Atualiza o documento em memória simulando a ação concorrente de outro usuário
      final conflictDoc = existing.copyWith(
        version: existing.version + 1,
        status: DocumentStatus.reviewed,
        updatedAt: DateTime.now(),
        extractedData: {
          ...?existing.extractedData,
          'observations':
              'Conferência aprovada em paralelo por outro advogado.',
        },
      );
      _mockDocuments[index] = conflictDoc;

      throw ConflictException(
        'Conflito de Concorrência (HTTP 409): O documento "${document.originalName}" foi modificado por outro usuário às ${DateFormat('HH:mm:ss').format(conflictDoc.updatedAt ?? DateTime.now())}.',
        latestDocument: conflictDoc,
      );
    }

    if (document.version < existing.version) {
      throw ConflictException(
        'Conflito de Concorrência (HTTP 409): A versão local do documento (v${document.version}) está desatualizada em relação à versão mais recente (v${existing.version}).',
        latestDocument: existing,
      );
    }

    final updated = document.copyWith(
      version: existing.version + 1,
      updatedAt: DateTime.now(),
    );

    _mockDocuments[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockDocuments.removeWhere((doc) => doc.id == documentId);
  }

  String _inferDocType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.contains('cnh')) return 'CNH';
    if (lower.contains('rg') || lower.contains('identidade') || lower.contains('cpf')) {
      return 'Identidade (RG)';
    }
    if (lower.contains('residencia') || lower.contains('comprovante')) {
      return 'Comprovante de Residência';
    }
    if (lower.contains('laudo') || lower.contains('pericial') || lower.contains('medico')) {
      return 'Laudo Médico / Pericial';
    }
    if (lower.contains('procuracao')) return 'Procuração';
    if (lower.contains('contrato') || lower.contains('estatuto')) return 'Contrato';
    if (lower.contains('certidao')) return 'Certidão';
    return 'Outros';
  }
}
