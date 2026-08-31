import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../core/routes/app_routes.dart';
import '../domain/models/client_model.dart';
import '../domain/models/document_model.dart';
import '../repository/client_repository.dart';
import '../repository/client_repository_impl.dart';
import '../repository/document_repository.dart';

/// Controller do formulário de cliente com upload de documentos e conferência.
///
/// Gerencia 3 abas:
/// 1. Dados do cliente (cadastro/edição)
/// 2. Upload de documentos (dropzone + file picker)
/// 3. Split view de conferência (visualizador + dados extraídos)
class ClientFormController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final ClientRepository clientRepository;
  final DocumentRepository documentRepository;

  ClientFormController({
    required this.clientRepository,
    required this.documentRepository,
  });

  // ─── Tipos de Documentos Predefinidos ─────────────────────────────
  static const List<String> documentTypes = [
    'Identidade (RG)',
    'CNH',
    'Comprovante de Residência',
    'Laudo Médico / Pericial',
    'Procuração',
    'Contrato',
    'Certidão',
    'Outros',
  ];

  // ─── Tab Controller ────────────────────────────────────────────────
  late TabController tabController;

  // ─── Estado do Formulário de Cliente ───────────────────────────────
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final cpfController = TextEditingController();
  final rgController = TextEditingController();
  final cityController = TextEditingController();

  final RxBool isSaving = false.obs;
  final RxBool isLoadingClient = false.obs;
  final RxnString clientError = RxnString();

  /// ID do cliente sendo editado (null = cadastro novo)
  String? editingClientId;

  /// Indica se o form está em modo de edição
  bool get isEditing => editingClientId != null;

  // ─── Estado do Upload de Documentos ────────────────────────────────
  final RxList<DocumentUploadItem> uploadQueue = <DocumentUploadItem>[].obs;
  final RxBool isUploading = false.obs;

  // ─── Estado da Conferência / Split View ────────────────────────────
  final RxList<DocumentModel> documents = <DocumentModel>[].obs;
  final Rxn<DocumentModel> selectedDocument = Rxn<DocumentModel>();
  final RxBool isLoadingDocuments = false.obs;
  final RxBool isProcessingDocument = false.obs;
  final RxDouble processingProgress = 0.0.obs;

  // Controllers para edição dos dados extraídos na conferência
  final standardizedNameController = TextEditingController();
  final documentTypeController = TextEditingController();
  final RxString selectedDocumentType = 'Identidade (RG)'.obs;
  final documentDateController = TextEditingController();
  final observationsController = TextEditingController();

  /// Título reativo para evitar leitura de controller durante pop transitions
  final RxString clientNameTitle = ''.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);

    // Verifica se há um client nos arguments (modo edição)
    final args = Get.arguments;
    if (args is ClientModel) {
      editingClientId = args.id;
      clientNameTitle.value = args.name;
      _loadClientData(args);
      _loadDocuments(args.id);
    }

    if (Get.currentRoute == AppRoutes.clientDetails) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (tabController.length > 2) {
          tabController.animateTo(2);
        }
      });
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SEÇÃO 1 — Dados do Cliente
  // ═══════════════════════════════════════════════════════════════════

  /// Preenche os campos com dados do cliente (modo edição)
  void _loadClientData(ClientModel client) {
    nameController.text = client.name;
    clientNameTitle.value = client.name;
    cpfController.text = client.cpf;
    rgController.text = client.rg;
    cityController.text = client.city;
  }

  /// Salva (cria ou atualiza) o cliente
  Future<void> saveClient() async {
    if (!formKey.currentState!.validate()) return;

    isSaving.value = true;
    clientError.value = null;

    try {
      final clientData = ClientModel(
        id: editingClientId ?? '',
        name: nameController.text.trim(),
        cpf: cpfController.text.trim(),
        rg: rgController.text.trim(),
        city: cityController.text.trim(),
        createdAt: DateTime.now(),
      );

      ClientModel savedClient;
      if (isEditing) {
        savedClient = await clientRepository.updateClient(clientData);
        _showSuccessSnackbar('Cliente atualizado com sucesso.');
      } else {
        savedClient = await clientRepository.createClient(clientData);
        editingClientId = savedClient.id;
        _showSuccessSnackbar('Cliente cadastrado com sucesso.');
      }

      // Se há arquivos na fila, faz upload automaticamente
      if (uploadQueue.isNotEmpty) {
        await _uploadAllDocuments();
      }
    } on ConflictException catch (e) {
      _showConflictSnackbar(e.message);
    } catch (e) {
      clientError.value = e.toString();
      _showErrorSnackbar('Erro ao salvar cliente: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SEÇÃO 2 — Upload de Documentos
  // ═══════════════════════════════════════════════════════════════════

  /// Adiciona arquivos à fila de upload
  void addFilesToQueue(List<DocumentUploadItem> files) {
    // Filtra tipos aceitos
    const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'docx'];
    for (final file in files) {
      final ext = file.fileName.split('.').last.toLowerCase();
      if (allowedExtensions.contains(ext)) {
        uploadQueue.add(file);
      } else {
        _showErrorSnackbar(
          'Arquivo "${file.fileName}" não aceito. Formatos: PDF, JPEG, PNG, DOCX.',
        );
      }
    }
  }

  /// Remove um arquivo da fila antes do envio
  void removeFromQueue(int index) {
    if (index >= 0 && index < uploadQueue.length) {
      uploadQueue.removeAt(index);
    }
  }

  /// Limpa toda a fila de upload
  void clearQueue() => uploadQueue.clear();

  /// Envia todos os arquivos da fila
  Future<void> uploadAllDocuments() async {
    if (editingClientId == null) {
      // Salva o cliente primeiro se ainda não tem ID
      await saveClient();
      if (editingClientId == null) return; // falhou ao salvar
    }
    await _uploadAllDocuments();
  }

  Future<void> _uploadAllDocuments() async {
    if (uploadQueue.isEmpty || editingClientId == null) return;

    isUploading.value = true;
    final clientId = editingClientId!;

    for (var i = 0; i < uploadQueue.length; i++) {
      final item = uploadQueue[i];
      uploadQueue[i] = item.copyWith(status: UploadItemStatus.uploading);

      try {
        final doc = await documentRepository.uploadDocument(
          clientId: clientId,
          fileName: item.fileName,
          fileType: item.fileName.split('.').last.toLowerCase(),
          fileSizeBytes: item.fileSizeBytes,
        );

        uploadQueue[i] = item.copyWith(status: UploadItemStatus.done);
        documents.add(doc);
      } catch (e) {
        uploadQueue[i] = item.copyWith(
          status: UploadItemStatus.error,
          errorMessage: e.toString(),
        );
      }
    }

    // Remove os enviados com sucesso
    uploadQueue.removeWhere((item) => item.status == UploadItemStatus.done);
    isUploading.value = false;

    if (documents.isNotEmpty) {
      _showSuccessSnackbar('Upload concluído. Documentos prontos para conferência.');
      // Vai para a aba de conferência
      tabController.animateTo(2);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SEÇÃO 3 — Conferência / Split View
  // ═══════════════════════════════════════════════════════════════════

  /// Carrega a lista de documentos do cliente
  Future<void> _loadDocuments(String clientId) async {
    isLoadingDocuments.value = true;
    try {
      final docs = await documentRepository.getDocumentsByClientId(clientId);
      documents.assignAll(docs);
    } catch (e) {
      _showErrorSnackbar('Erro ao carregar documentos: $e');
    } finally {
      isLoadingDocuments.value = false;
    }
  }

  /// Gera o nome padronizado do documento segundo a regra:
  /// [TIPO_DOCUMENTO]_[PRIMEIRO_NOME]_[DATA_ENVIO].[extensao]
  String generateStandardizedName({
    required String docType,
    required DocumentModel doc,
  }) {
    final cleanType = _sanitizeNamePart(docType);

    // Primeiro nome do cliente (ou CLIENTE se vazio)
    final clientName = nameController.text.trim();
    final firstName = clientName.isNotEmpty
        ? _sanitizeNamePart(clientName.split(' ').first)
        : 'CLIENTE';

    // Data de envio/criação formatada dd_MM_yyyy
    final dateStr = DateFormat('dd_MM_yyyy').format(doc.createdAt);

    // Extensão do arquivo original
    final ext = doc.fileType.toLowerCase();

    return '${cleanType}_${firstName}_$dateStr.$ext';
  }

  static String _sanitizeNamePart(String input) {
    var result = input.toUpperCase();
    const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    const withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    result = result.replaceAll(RegExp(r'[^A-Z0-9]'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    return result.replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Seleciona um documento para conferência na split view
  void selectDocument(DocumentModel doc) {
    selectedDocument.value = doc;

    final extractedType = doc.extractedData?['document_type']?.toString();
    final validDocType = (extractedType != null && documentTypes.contains(extractedType))
        ? extractedType
        : _inferMatchingType(doc);

    selectedDocumentType.value = validDocType;
    documentTypeController.text = validDocType;

    // Nome padronizado: usa o existente ou gera com base no tipo + primeiro nome + data
    standardizedNameController.text = doc.standardizedName ??
        generateStandardizedName(docType: validDocType, doc: doc);

    // Data formatada dd/MM/yyyy
    final rawDate = doc.extractedData?['document_date']?.toString();
    if (rawDate != null && rawDate.isNotEmpty) {
      documentDateController.text = rawDate;
    } else {
      documentDateController.text = DateFormat('dd/MM/yyyy').format(doc.createdAt);
    }

    observationsController.text =
        doc.extractedData?['observations']?.toString() ?? '';
  }

  /// Callback acionado quando o usuário altera a seleção do tipo de documento
  void onDocumentTypeChanged(String? newType) {
    if (newType == null) return;
    selectedDocumentType.value = newType;
    documentTypeController.text = newType;

    final doc = selectedDocument.value;
    if (doc != null) {
      standardizedNameController.text = generateStandardizedName(
        docType: newType,
        doc: doc,
      );
    }
  }

  String _inferMatchingType(DocumentModel doc) {
    final lower = doc.originalName.toLowerCase();
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

  /// Inicia o processamento de IA do documento selecionado
  Future<void> processSelectedDocument() async {
    final doc = selectedDocument.value;
    if (doc == null || doc.isReviewed) return;

    isProcessingDocument.value = true;
    processingProgress.value = 0.0;

    // Atualiza status para processing
    _updateDocumentInList(doc.copyWith(status: DocumentStatus.processing));

    // Simula progresso gradual enquanto espera a resposta
    final random = Random();
    final totalDuration = 4 + random.nextInt(4); // 4-7 segundos
    final progressTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (timer) {
        final elapsed = timer.tick * 0.2;
        processingProgress.value = (elapsed / totalDuration).clamp(0.0, 0.95);
      },
    );

    try {
      final processed = await documentRepository.processDocument(doc.id);
      progressTimer.cancel();
      processingProgress.value = 1.0;

      // Define o tipo e gera o nome padronizado
      final inferredType = processed.extractedData?['document_type']?.toString() ?? 'Outros';
      final validDocType = documentTypes.contains(inferredType) ? inferredType : 'Outros';
      selectedDocumentType.value = validDocType;

      final finalStandardizedName = generateStandardizedName(
        docType: validDocType,
        doc: processed,
      );

      final withStandardized = processed.copyWith(
        standardizedName: finalStandardizedName,
        status: DocumentStatus.awaitingReview, // Status: Aguardando Conferência
      );

      await documentRepository.updateDocument(withStandardized);
      _updateDocumentInList(withStandardized);
      selectDocument(withStandardized);

      _showSuccessSnackbar('Processamento de IA concluído. Documento aguardando conferência.');
    } catch (e) {
      progressTimer.cancel();
      _updateDocumentInList(
        doc.copyWith(
          status: DocumentStatus.error,
          errorMessage: e.toString(),
        ),
      );
      _showErrorSnackbar('Erro no processamento: $e');
    } finally {
      isProcessingDocument.value = false;
      processingProgress.value = 0.0;
    }
  }

  /// Aprova a conferência do documento (salva dados editados e muda status para Conferido)
  Future<void> approveDocument() async {
    final doc = selectedDocument.value;
    if (doc == null || doc.isReviewed) return;

    try {
      final updated = doc.copyWith(
        standardizedName: standardizedNameController.text.trim(),
        status: DocumentStatus.reviewed, // Status: Conferido
        extractedData: {
          'document_type': selectedDocumentType.value,
          'document_date': documentDateController.text.trim(),
          'observations': observationsController.text.trim(),
        },
      );

      final saved = await documentRepository.updateDocument(updated);
      _updateDocumentInList(saved);
      selectDocument(saved);

      _showSuccessSnackbar('Documento conferido e aprovado com sucesso!');
    } on ConflictException catch (e) {
      _showConflictSnackbar(e.message);
    } catch (e) {
      _showErrorSnackbar('Erro ao salvar conferência: $e');
    }
  }

  /// Deleta o documento selecionado
  Future<void> deleteSelectedDocument() async {
    final doc = selectedDocument.value;
    if (doc == null) return;

    try {
      await documentRepository.deleteDocument(doc.id);
      documents.removeWhere((d) => d.id == doc.id);
      selectedDocument.value = null;
      _showSuccessSnackbar('Documento excluído.');
    } catch (e) {
      _showErrorSnackbar('Erro ao excluir documento: $e');
    }
  }

  /// Volta para a listagem de clientes
  void goBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  // ─── Helpers internos ──────────────────────────────────────────────

  void _updateDocumentInList(DocumentModel updated) {
    final index = documents.indexWhere((d) => d.id == updated.id);
    if (index != -1) {
      documents[index] = updated;
      documents.refresh();
    }
    if (selectedDocument.value?.id == updated.id) {
      selectedDocument.value = updated;
    }
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Sucesso',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade800,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Erro',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade800,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  void _showConflictSnackbar(String message) {
    Get.snackbar(
      'Conflito de Atendimento',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.amber.shade900,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
    );
  }
}

/// Item da fila de upload (representação local antes do envio)
class DocumentUploadItem {
  final String fileName;
  final int fileSizeBytes;
  final UploadItemStatus status;
  final String? errorMessage;

  const DocumentUploadItem({
    required this.fileName,
    required this.fileSizeBytes,
    this.status = UploadItemStatus.queued,
    this.errorMessage,
  });

  DocumentUploadItem copyWith({
    String? fileName,
    int? fileSizeBytes,
    UploadItemStatus? status,
    String? errorMessage,
  }) {
    return DocumentUploadItem(
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Tamanho formatado (KB/MB)
  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

enum UploadItemStatus { queued, uploading, done, error }
