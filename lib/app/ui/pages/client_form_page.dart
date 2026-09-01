import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/client_form_controller.dart';
import '../../core/app_theme.dart';
import '../../domain/models/document_model.dart';
import '../widgets/document_dropzone.dart';
import '../widgets/document_split_view.dart';

/// Página principal do formulário de cliente com 3 abas:
/// 1. Dados do Cliente
/// 2. Upload de Documentos (Dropzone & Seleção)
/// 3. Conferência e Split View de Documentos
class ClientFormPage extends GetView<ClientFormController> {
  const ClientFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Barra Superior de Navegação & Ações
            _buildTopNavBar(),

            // Conteúdo Principal com Tabs
            Expanded(
              child: Column(
                children: [
                  // TabBar Estilizada
                  _buildTabBar(),

                  // Conteúdo das Abas
                  Expanded(
                    child: TabBarView(
                      controller: controller.tabController,
                      children: [
                        // Aba 1: Dados do Cliente
                        _buildClientDataTab(context),

                        // Aba 2: Upload de Documentos
                        _buildUploadTab(context),

                        // Aba 3: Conferência e Split View
                        _buildConferenceTab(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra de navegação superior com botão voltar e título
  Widget _buildTopNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: controller.goBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppTheme.textPrimary,
            tooltip: 'Voltar para listagem',
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Obx(() {
                final isEdit = controller.isEditing;
                final name = controller.clientNameTitle.value;
                return Text(
                  isEdit
                      ? 'Editar Cliente: $name'
                      : 'Novo Cadastro de Cliente',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                );
              }),
              const Text(
                'DOC Intelligence • Gestão e Conferência Documental',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Botão de Salvar Cliente
          Obx(() {
            return ElevatedButton.icon(
              onPressed: controller.isSaving.value ? null : controller.saveClient,
              icon: controller.isSaving.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0E0E10),
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(
                controller.isSaving.value
                    ? 'Salvando...'
                    : (controller.isEditing ? 'Salvar Alterações' : 'Salvar Cliente'),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Barra de Abas
  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: TabBar(
        controller: controller.tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 3,
        tabs: [
          const Tab(
            icon: Icon(Icons.badge_outlined, size: 18),
            text: '1. Dados do Cliente',
          ),
          Tab(
            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
            child: Obx(() {
              final queueCount = controller.uploadQueue.length;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('2. Upload de Documentos'),
                  if (queueCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$queueCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0E0E10),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
          Tab(
            icon: const Icon(Icons.document_scanner_outlined, size: 18),
            child: Obx(() {
              final docCount = controller.documents.length;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('3. Conferência (Split View)'),
                  if (docCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        '$docCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ABA 1: Dados do Cliente
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildClientDataTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            color: AppTheme.primary, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Informações Cadastrais do Cliente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Preencha os dados do cliente. Você poderá anexar documentos na próxima etapa.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: AppTheme.border),
                    const SizedBox(height: 24),

                    // Campo: Nome Completo
                    const Text(
                      'Nome Completo *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.nameController,
                      decoration: const InputDecoration(
                        hintText: 'Ex: João Fictício da Silva',
                        prefixIcon: Icon(Icons.person_rounded,
                            size: 18, color: AppTheme.textMuted),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome do cliente';
                        }
                        if (value.trim().length < 3) {
                          return 'O nome deve ter no mínimo 3 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Linha: CPF e RG
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CPF
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CPF *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: controller.cpfController,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  _CpfInputFormatter(),
                                ],
                                decoration: const InputDecoration(
                                  hintText: '000.000.000-00',
                                  prefixIcon: Icon(Icons.badge_outlined,
                                      size: 18, color: AppTheme.textMuted),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Informe o CPF';
                                  }
                                  if (value.length < 14) {
                                    return 'CPF inválido';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // RG
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RG *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: controller.rgController,
                                decoration: const InputDecoration(
                                  hintText: 'Ex: 12.345.678-9',
                                  prefixIcon: Icon(
                                      Icons.credit_card_outlined,
                                      size: 18,
                                      color: AppTheme.textMuted),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Informe o RG';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Campo: Cidade / UF
                    const Text(
                      'Cidade / UF *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.cityController,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Curitiba - PR',
                        prefixIcon: Icon(Icons.location_city_outlined,
                            size: 18, color: AppTheme.textMuted),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe a cidade e UF';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Botões de Ação Inferiores
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: controller.goBack,
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (controller.formKey.currentState!.validate()) {
                              controller.tabController.animateTo(1);
                            }
                          },
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: const Text('Avançar para Documentos'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ABA 2: Upload de Documentos
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildUploadTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.drive_folder_upload_outlined,
                          color: AppTheme.primary, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Upload de Documentos do Cliente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Adicione contratos, procurações, comprovantes ou documentos de identificação para análise automática por IA.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: AppTheme.border),
                  const SizedBox(height: 24),

                  // Dropzone e Fila de Upload
                  Obx(() {
                    return DocumentDropzone(
                      onFilesSelected: controller.addFilesToQueue,
                      queue: controller.uploadQueue,
                      onRemoveItem: controller.removeFromQueue,
                      onClearQueue: controller.clearQueue,
                      onStartUpload: controller.uploadAllDocuments,
                      isUploading: controller.isUploading.value,
                    );
                  }),

                  // Lista de Documentos Já Carregados (Exibida imediatamente após o upload)
                  Obx(() {
                    if (controller.documents.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        const Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Documentos Carregados (${controller.documents.length})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  controller.tabController.animateTo(2),
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 16),
                              label: const Text('Ir para Conferência (Split View)'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.documents.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final doc = controller.documents[index];
                            return _UploadedDocumentRow(
                              document: doc,
                              onTap: () {
                                controller.selectDocument(doc);
                                controller.tabController.animateTo(2);
                              },
                            );
                          },
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ABA 3: Conferência e Split View
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildConferenceTab(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingDocuments.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        );
      }

      if (controller.documents.isEmpty) {
        return _buildEmptyDocumentsState();
      }

      if (controller.selectedDocument.value == null &&
          controller.documents.isNotEmpty) {
        controller.selectDocument(controller.documents.first);
      }

      final currentSelected = controller.selectedDocument.value ??
          controller.documents.first;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carrossel Horizontal de Seleção de Documentos
                _buildDocumentSelectorHeader(currentSelected),
                const SizedBox(height: 20),

                // Split View Principal
                DocumentSplitView(
                  document: currentSelected,
                  standardizedNameController:
                      controller.standardizedNameController,
                  selectedDocumentType: controller.selectedDocumentType.value,
                  onDocumentTypeChanged: controller.onDocumentTypeChanged,
                  documentDateController: controller.documentDateController,
                  observationsController: controller.observationsController,
                  isProcessing: controller.isProcessingDocument.value,
                  processingProgress: controller.processingProgress.value,
                  onProcessWithAi: controller.processSelectedDocument,
                  onApprove: controller.approveDocument,
                  onDelete: controller.deleteSelectedDocument,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Barra de seleção rápida com mini-cards dos documentos disponíveis
  Widget _buildDocumentSelectorHeader(DocumentModel currentSelected) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_shared_outlined,
                  size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Documentos Carregados (${controller.documents.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => controller.tabController.animateTo(1),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Adicionar Mais'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: controller.documents.map((doc) {
                final isSelected = doc.id == currentSelected.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => controller.selectDocument(doc),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentSubtle
                            : AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            doc.fileType.toLowerCase() == 'pdf'
                                ? Icons.picture_as_pdf_outlined
                                : Icons.image_outlined,
                            size: 16,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              doc.originalName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildMiniStatusDot(doc.status),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatusDot(DocumentStatus status) {
    Color color;
    switch (status) {
      case DocumentStatus.reviewed:
        color = AppTheme.success;
        break;
      case DocumentStatus.awaitingReview:
        color = AppTheme.warning;
        break;
      case DocumentStatus.processing:
        color = AppTheme.primary;
        break;
      case DocumentStatus.error:
        color = AppTheme.danger;
        break;
      default:
        color = AppTheme.textMuted;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildEmptyDocumentsState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_off_outlined,
              size: 48,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum documento carregado para este cliente',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vá para a aba de Upload para anexar os primeiros documentos.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => controller.tabController.animateTo(1),
            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
            label: const Text('Ir para Upload de Documentos'),
          ),
        ],
      ),
    );
  }
}

/// Formatador de máscara para CPF: 000.000.000-00
class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 11; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _UploadedDocumentRow extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;

  const _UploadedDocumentRow({
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPdf = document.fileType.toLowerCase() == 'pdf';
    final iconData =
        isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined;
    final iconColor = isPdf ? const Color(0xFFF87171) : AppTheme.info;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.standardizedName ?? document.originalName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${document.fileSizeFormatted} • ${document.fileType.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildStatusBadge(document.status),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DocumentStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case DocumentStatus.reviewed:
        bg = AppTheme.successBg;
        fg = AppTheme.success;
        break;
      case DocumentStatus.awaitingReview:
        bg = AppTheme.warningBg;
        fg = AppTheme.warning;
        break;
      case DocumentStatus.processing:
        bg = AppTheme.accentSubtle;
        fg = AppTheme.primary;
        break;
      case DocumentStatus.error:
        bg = AppTheme.dangerBg;
        fg = AppTheme.danger;
        break;
      default:
        bg = AppTheme.surfaceMuted;
        fg = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
