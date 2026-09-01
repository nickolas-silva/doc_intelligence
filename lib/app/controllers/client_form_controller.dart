import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/routes/app_routes.dart';
import '../domain/models/client_model.dart';
import '../domain/models/document_model.dart';
import '../repository/client_repository.dart';
import '../repository/document_repository.dart';
import '../repository/mock_document_repository.dart';

/// Controller do formulário de cliente com upload de documentos e conferência.
///
/// Gerencia 3 abas:
/// 1. Dados do cliente (cadastro/edição)
/// 2. Upload de documentos (dropzone + file picker + detecção de duplicatas)
/// 3. Split view de conferência (visualizador + dados extraídos + controle de concorrência 409)
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

  /// Se está no modo de edição (reativo)
  final RxBool isEditing = false.obs;

  /// Título com nome do cliente para o cabeçalho (reativo)
  final RxString clientNameTitle = 'Novo Cadastro de Cliente'.obs;

  // ─── Estado do Upload ──────────────────────────────────────────────
  final RxList<DocumentUploadItem> uploadQueue = <DocumentUploadItem>[].obs;
  final RxBool isUploading = false.obs;

  // ─── Estado da Conferência / Split View ────────────────────────────
  final RxList<DocumentModel> documents = <DocumentModel>[].obs;
  final Rxn<DocumentModel> selectedDocument = Rxn<DocumentModel>();
  final RxBool isLoadingDocuments = false.obs;
  final RxBool isProcessingDocument = false.obs;
  final RxDouble processingProgress = 0.0.obs;

  // ─── Controladores da Split View ───────────────────────────────────
  final standardizedNameController = TextEditingController();
  final RxString selectedDocumentType = 'Outros'.obs;
  final documentDateController = TextEditingController();
  final observationsController = TextEditingController();

  final _dateFormat = DateFormat('dd/MM/yyyy');

  /// Flag reativa indicando se há conflito 409 simulado ativo
  final RxBool isSimulateConflictActive = false.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);

    // 1. Tenta carregar através de Get.arguments
    final args = Get.arguments;
    if (args is ClientModel) {
      editingClientId = args.id;
      isEditing.value = true;
      nameController.text = args.name;
      cpfController.text = args.cpf;
      rgController.text = args.rg;
      cityController.text = args.city;
      clientNameTitle.value = args.name;
      _loadDocuments(args.id);
      if (Get.currentRoute == AppRoutes.clientDetails) {
        tabController.index = 2; // Abre direto na Split View
      }
      return;
    } else if (args is String && args.isNotEmpty && args != 'cadastrar') {
      editingClientId = args;
      isEditing.value = true;
      _loadClient(args);
      _loadDocuments(args);
      if (Get.currentRoute == AppRoutes.clientDetails) {
        tabController.index = 2;
      }
      return;
    }

    // 2. Tenta carregar através de Get.parameters['id'] (ex: URL /clients/form?id=1)
    final param = Get.parameters['id'];
    if (param != null && param.isNotEmpty && param != 'cadastrar') {
      editingClientId = param;
      isEditing.value = true;
      _loadClient(param);
      _loadDocuments(param);
      if (Get.currentRoute == AppRoutes.clientDetails) {
        tabController.index = 2;
      }
    } else {
      isEditing.value = false;
      clientNameTitle.value = 'Novo Cadastro de Cliente';
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  /// Retorna para a listagem com segurança
  void goBack() {
    Get.back();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SEÇÃO 1 — Dados do Cliente
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _loadClient(String clientId) async {
    isLoadingClient.value = true;
    clientError.value = null;
    try {
      final client = await clientRepository.getClientById(clientId);
      nameController.text = client.name;
      cpfController.text = client.cpf;
      rgController.text = client.rg;
      cityController.text = client.city;
      clientNameTitle.value = client.name;
    } catch (e) {
      clientError.value = e.toString();
      _showErrorSnackbar('Erro ao carregar dados do cliente: $e');
    } finally {
      isLoadingClient.value = false;
    }
  }

  /// Salva os dados do cliente (criação ou edição)
  Future<void> saveClient() async {
    if (formKey.currentState != null) {
      if (!formKey.currentState!.validate()) {
        _showErrorSnackbar('Preencha os campos obrigatórios corretamente.');
        return;
      }
    } else {
      // Validação alternativa caso o formulário não esteja montado na tela atual
      if (nameController.text.trim().isEmpty) {
        _showErrorSnackbar('Preencha o nome do cliente na Aba 1 antes de continuar.');
        tabController.animateTo(0);
        return;
      }
    }

    isSaving.value = true;
    clientError.value = null;

    final name = nameController.text.trim();
    final cpf = cpfController.text.trim();
    final rg = rgController.text.trim();
    final city = cityController.text.trim();

    try {
      if (editingClientId == null) {
        // Criar novo cliente
        final newClient = await clientRepository.createClient(
          ClientModel(
            id: '',
            name: name,
            cpf: cpf,
            rg: rg,
            city: city,
            totalDocuments: 0,
            createdAt: DateTime.now(),
          ),
        );
        editingClientId = newClient.id;
        isEditing.value = true;
        clientNameTitle.value = newClient.name;
        _showSuccessSnackbar('Cliente cadastrado com sucesso!');
      } else {
        // Atualizar cliente existente
        final updated = ClientModel(
          id: editingClientId!,
          name: name,
          cpf: cpf,
          rg: rg,
          city: city,
          totalDocuments: documents.length,
          createdAt: DateTime.now(),
        );
        await clientRepository.updateClient(updated);
        clientNameTitle.value = name;
        _showSuccessSnackbar('Dados do cliente atualizados com sucesso!');
      }
    } on ConflictException catch (e) {
      _handleConflict(e);
    } catch (e) {
      clientError.value = e.toString();
      _showErrorSnackbar('Erro ao salvar cliente: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SEÇÃO 2 — Upload de Documentos e Detecção de Duplicatas
  // ═══════════════════════════════════════════════════════════════════

  /// Calcula hash SHA-256 a partir dos bytes ou metadados
  String calculateFileHash(Uint8List? bytes, String fileName, int size) {
    if (bytes != null && bytes.isNotEmpty) {
      return sha256.convert(bytes).toString();
    }
    return sha256.convert(utf8.encode('${fileName}_$size')).toString();
  }

  /// Adiciona arquivos à fila de upload com validação de duplicatas
  void addFilesToQueue(List<DocumentUploadItem> files) {
    const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'docx'];
    final duplicates = <String>[];

    for (final file in files) {
      final ext = file.fileName.split('.').last.toLowerCase();
      if (allowedExtensions.contains(ext)) {
        final hash = calculateFileHash(
          file.bytes,
          file.fileName,
          file.fileSizeBytes,
        );

        // 1. Verifica se já existe nos documentos carregados do cliente
        final existingDoc = documents.firstWhereOrNull(
          (d) =>
              (d.fileHash != null && d.fileHash == hash) ||
              (d.originalName == file.fileName &&
                  d.fileSizeBytes == file.fileSizeBytes),
        );

        // 2. Verifica se já está na fila
        final inQueue = uploadQueue.firstWhereOrNull(
          (item) =>
              (item.fileHash != null && item.fileHash == hash) ||
              (item.fileName == file.fileName &&
                  item.fileSizeBytes == file.fileSizeBytes),
        );

        final isDuplicate = existingDoc != null || inQueue != null;
        String? duplicateReason;
        if (existingDoc != null) {
          duplicateReason =
              'Conteúdo idêntico a "${existingDoc.originalName}" já cadastrado para este cliente.';
          duplicates.add(file.fileName);
        } else if (inQueue != null) {
          duplicateReason = 'Arquivo duplicado já presente na fila de envio.';
          duplicates.add(file.fileName);
        }

        uploadQueue.add(
          file.copyWith(
            fileHash: hash,
            isDuplicate: isDuplicate,
            duplicateReason: duplicateReason,
          ),
        );
      } else {
        _showErrorSnackbar(
          'Arquivo "${file.fileName}" não aceito. Formatos: PDF, JPEG, PNG, DOCX.',
        );
      }
    }

    uploadQueue.refresh();

    if (duplicates.isNotEmpty) {
      _showWarningSnackbar(
        'Atenção: ${duplicates.length} arquivo(s) duplicado(s) detectado(s) na fila.',
      );
    }
  }

  /// Remove um arquivo da fila antes do envio
  void removeFromQueue(int index) {
    if (index >= 0 && index < uploadQueue.length) {
      uploadQueue.removeAt(index);
      uploadQueue.refresh();
    }
  }

  /// Remove todos os itens marcados como duplicados da fila
  void removeDuplicatesFromQueue() {
    final count = uploadQueue.where((item) => item.isDuplicate).length;
    uploadQueue.removeWhere((item) => item.isDuplicate);
    uploadQueue.refresh();
    _showSuccessSnackbar('$count arquivo(s) duplicado(s) removido(s) da fila.');
  }

  /// Limpa toda a fila de upload
  void clearQueue() {
    uploadQueue.clear();
    uploadQueue.refresh();
  }

  /// Verifica se há duplicatas na fila
  bool get hasDuplicatesInQueue =>
      uploadQueue.any((item) => item.isDuplicate);

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
          bytes: item.bytes,
          fileHash: item.fileHash,
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
      if (selectedDocument.value == null ||
          !documents.any((d) => d.id == selectedDocument.value?.id)) {
        selectDocument(documents.first);
      }
      documents.refresh();
      _showSuccessSnackbar('Upload concluído com sucesso!');
      tabController.animateTo(2);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SEÇÃO 3 — Conferência / Split View & Concorrência
  // ═══════════════════════════════════════════════════════════════════

  /// Carrega a lista de documentos do cliente
  Future<void> _loadDocuments(String clientId) async {
    isLoadingDocuments.value = true;
    try {
      final docs = await documentRepository.getDocumentsByClientId(clientId);
      documents.assignAll(docs);
      if (documents.isNotEmpty) {
        if (selectedDocument.value == null ||
            !documents.any((d) => d.id == selectedDocument.value?.id)) {
          selectDocument(documents.first);
        }
      }
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

    final clientName = nameController.text.trim();
    final firstName = clientName.isNotEmpty
        ? _sanitizeNamePart(clientName.split(' ').first)
        : 'CLIENTE';

    final dateStr = DateFormat('dd_MM_yyyy').format(doc.createdAt);
    final ext = doc.fileType.toLowerCase();

    return '${cleanType}_${firstName}_$dateStr.$ext';
  }

  String _sanitizeNamePart(String input) {
    var text = input.toUpperCase().trim();
    const withDia = 'ÀÁÂÃÄÅÒÓÔÕÖØÈÉÊËÇÌÍÎÏÙÚÛÜÑ';
    const withoutDia = 'AAAAAAOOOOOOEEEECCIIIIUUUUN';
    for (int i = 0; i < withDia.length; i++) {
      text = text.replaceAll(withDia[i], withoutDia[i]);
    }
    text = text.replaceAll(RegExp(r'[^A-Z0-9]'), '_');
    text = text.replaceAll(RegExp(r'_+'), '_');
    return text.replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Seleciona um documento para conferência na Split View
  void selectDocument(DocumentModel doc) {
    selectedDocument.value = doc;

    final extType = doc.extractedData?['document_type']?.toString();
    final validType = (extType != null && documentTypes.contains(extType))
        ? extType
        : 'Outros';

    selectedDocumentType.value = validType;

    if (doc.standardizedName != null && doc.standardizedName!.isNotEmpty) {
      standardizedNameController.text = doc.standardizedName!;
    } else {
      standardizedNameController.text = generateStandardizedName(
        docType: validType,
        doc: doc,
      );
    }

    final rawDate = doc.extractedData?['document_date']?.toString();
    if (rawDate != null && rawDate.isNotEmpty) {
      documentDateController.text = rawDate;
    } else {
      documentDateController.text = _dateFormat.format(doc.createdAt);
    }

    observationsController.text =
        doc.extractedData?['observations']?.toString() ?? '';
  }

  /// Callback acionado quando o usuário altera o tipo de documento
  void onDocumentTypeChanged(String? newType) {
    if (newType == null) return;
    selectedDocumentType.value = newType;

    final doc = selectedDocument.value;
    if (doc != null) {
      standardizedNameController.text = generateStandardizedName(
        docType: newType,
        doc: doc,
      );
    }
  }

  /// Dispara a simulação de concorrência (HTTP 409) para teste
  void toggleSimulateConflict() {
    if (documentRepository is MockDocumentRepository) {
      final mockRepo = documentRepository as MockDocumentRepository;
      mockRepo.simulateConflictOnNextUpdate =
          !mockRepo.simulateConflictOnNextUpdate;
      isSimulateConflictActive.value = mockRepo.simulateConflictOnNextUpdate;

      if (isSimulateConflictActive.value) {
        _showWarningSnackbar(
          'Simulação Ativada: A próxima aprovação ou salvamento disparará Conflito 409.',
        );
      } else {
        _showSuccessSnackbar('Simulação de conflito desativada.');
      }
    }
  }

  /// Dispara o processamento por IA do documento selecionado
  Future<void> processSelectedDocument() async {
    final doc = selectedDocument.value;
    if (doc == null || doc.isReviewed) return;

    isProcessingDocument.value = true;
    processingProgress.value = 0.05;

    _updateDocumentInList(
      doc.copyWith(status: DocumentStatus.processing),
    );

    final random = Random();
    final totalDuration = 4 + random.nextInt(3);
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

      final inferredType =
          processed.extractedData?['document_type']?.toString() ?? 'Outros';
      final validDocType =
          documentTypes.contains(inferredType) ? inferredType : 'Outros';
      selectedDocumentType.value = validDocType;

      final finalStandardizedName = generateStandardizedName(
        docType: validDocType,
        doc: processed,
      );

      final withStandardized = processed.copyWith(
        standardizedName: finalStandardizedName,
        status: DocumentStatus.awaitingReview,
      );

      await documentRepository.updateDocument(withStandardized);
      _updateDocumentInList(withStandardized);
      selectDocument(withStandardized);

      _showSuccessSnackbar(
        'Processamento de IA concluído. Documento aguardando conferência.',
      );
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

  /// Aprova a conferência do documento (muda status para Conferido com tratamento de 409)
  Future<void> approveDocument() async {
    final doc = selectedDocument.value;
    if (doc == null || doc.isReviewed) return;

    try {
      final updated = doc.copyWith(
        standardizedName: standardizedNameController.text.trim(),
        status: DocumentStatus.reviewed,
        extractedData: {
          'document_type': selectedDocumentType.value,
          'document_date': documentDateController.text.trim(),
          'observations': observationsController.text.trim(),
        },
      );

      final saved = await documentRepository.updateDocument(updated);
      _updateDocumentInList(saved);
      selectDocument(saved);

      _showSuccessSnackbar(
        'Conferência aprovada com sucesso! Documento finalizado.',
      );
    } on ConflictException catch (e) {
      _handleConflict(e);
    } catch (e) {
      _showErrorSnackbar('Erro ao aprovar conferência: $e');
    }
  }

  /// Trata visualmente e interativamente exceções de concorrência (HTTP 409)
  void _handleConflict(ConflictException conflict) {
    isSimulateConflictActive.value = false;

    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.sync_problem_rounded,
                  color: AppTheme.warning,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Conflito de Concorrência (HTTP 409)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                conflict.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Fechar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Get.back();
                        if (editingClientId != null) {
                          await _loadDocuments(editingClientId!);
                          _showSuccessSnackbar(
                            'Dados mais recentes sincronizados com o servidor!',
                          );
                        }
                      },
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Recarregar Dados'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Exclui o documento selecionado
  Future<void> deleteSelectedDocument() async {
    final doc = selectedDocument.value;
    if (doc == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Excluir Documento'),
        content: Text('Deseja realmente excluir "${doc.originalName}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await documentRepository.deleteDocument(doc.id);
        documents.removeWhere((d) => d.id == doc.id);
        if (documents.isNotEmpty) {
          selectDocument(documents.first);
        } else {
          selectedDocument.value = null;
        }
        _showSuccessSnackbar('Documento excluído com sucesso.');
      } catch (e) {
        _showErrorSnackbar('Erro ao excluir documento: $e');
      }
    }
  }

  void _updateDocumentInList(DocumentModel updated) {
    final idx = documents.indexWhere((d) => d.id == updated.id);
    if (idx != -1) {
      documents[idx] = updated;
      documents.refresh();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Snackbars
  // ═══════════════════════════════════════════════════════════════════

  void _showSuccessSnackbar(String message) {
    if (Get.context == null) return;
    Get.snackbar(
      'Sucesso',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceMuted,
      colorText: AppTheme.textPrimary,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.check_circle_outline, color: AppTheme.success),
    );
  }

  void _showErrorSnackbar(String message) {
    if (Get.context == null) return;
    Get.snackbar(
      'Erro',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceMuted,
      colorText: AppTheme.textPrimary,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.error_outline, color: AppTheme.danger),
    );
  }

  void _showWarningSnackbar(String message) {
    if (Get.context == null) return;
    Get.snackbar(
      'Atenção',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceMuted,
      colorText: AppTheme.textPrimary,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
    );
  }
}

/// Item da fila de upload com suporte a hash e validação de duplicatas
class DocumentUploadItem {
  final String fileName;
  final int fileSizeBytes;
  final Uint8List? bytes;
  final String? fileHash;
  final bool isDuplicate;
  final String? duplicateReason;
  final UploadItemStatus status;
  final String? errorMessage;

  const DocumentUploadItem({
    required this.fileName,
    required this.fileSizeBytes,
    this.bytes,
    this.fileHash,
    this.isDuplicate = false,
    this.duplicateReason,
    this.status = UploadItemStatus.queued,
    this.errorMessage,
  });

  DocumentUploadItem copyWith({
    String? fileName,
    int? fileSizeBytes,
    Uint8List? bytes,
    String? fileHash,
    bool? isDuplicate,
    String? duplicateReason,
    UploadItemStatus? status,
    String? errorMessage,
  }) {
    return DocumentUploadItem(
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      bytes: bytes ?? this.bytes,
      fileHash: fileHash ?? this.fileHash,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      duplicateReason: duplicateReason ?? this.duplicateReason,
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
