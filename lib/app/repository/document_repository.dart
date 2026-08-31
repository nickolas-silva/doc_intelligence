import '../domain/models/document_model.dart';

/// Contrato para o repositório de documentos.
///
/// Não deve depender do pacote `get` conforme diretrizes de arquitetura.
abstract class DocumentRepository {
  Future<List<DocumentModel>> getDocumentsByClientId(String clientId);

  Future<DocumentModel> uploadDocument({
    required String clientId,
    required String fileName,
    required String fileType,
    required int fileSizeBytes,
    String? previewUrl,
  });

  Future<DocumentModel> processDocument(String documentId);

  Future<DocumentModel> updateDocument(DocumentModel document);

  Future<void> deleteDocument(String documentId);
}
