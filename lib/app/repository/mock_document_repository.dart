import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/document_model.dart';
import 'document_repository.dart';

/// Implementação Mock do repositório de documentos com dados fictícios,
/// integração com asset PDF e imagem padrão de demonstração.
///
/// Não deve importar ou depender do pacote `get`.
class MockDocumentRepository implements DocumentRepository {
  final _uuid = const Uuid();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  static const String defaultPdfAsset = 'assets/mock/desafio.pdf';
  static const String defaultImageUrl =
      'https://dummyimage.com/600x400/000/fff.png&text=Exemplo+de+documento';

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
        fileSizeBytes: 523953, // 512 KB
        status: DocumentStatus.reviewed,
        assetPath: defaultPdfAsset,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
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
    await Future.delayed(const Duration(milliseconds: 450));
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

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

    _mockDocuments[index] = document;
    return document;
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
