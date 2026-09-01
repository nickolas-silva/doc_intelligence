import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../controllers/client_form_controller.dart';
import '../../core/app_theme.dart';
import '../../domain/models/document_model.dart';

/// Tela de Conferência em Split View:
/// Lado Esquerdo: Visualizador de Documento Original (PDF / Imagem).
/// Lado Direito: Formulário com dados extraídos e padronizados pela IA.
class DocumentSplitView extends StatelessWidget {
  final DocumentModel document;
  final TextEditingController standardizedNameController;
  final String selectedDocumentType;
  final Function(String?) onDocumentTypeChanged;
  final TextEditingController documentDateController;
  final TextEditingController observationsController;
  final bool isProcessing;
  final double processingProgress;
  final VoidCallback onProcessWithAi;
  final VoidCallback onApprove;
  final VoidCallback onDelete;

  const DocumentSplitView({
    super.key,
    required this.document,
    required this.standardizedNameController,
    required this.selectedDocumentType,
    required this.onDocumentTypeChanged,
    required this.documentDateController,
    required this.observationsController,
    required this.isProcessing,
    required this.processingProgress,
    required this.onProcessWithAi,
    required this.onApprove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isReviewed = document.isReviewed;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 950;

        if (isStacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 480,
                child: _buildDocumentViewerPanel(),
              ),
              const SizedBox(height: 16),
              _buildExtractedDataPanel(isReviewed),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Painel Esquerdo: Visualizador
            Expanded(
              flex: 5,
              child: SizedBox(
                height: 720,
                child: _buildDocumentViewerPanel(),
              ),
            ),
            const SizedBox(width: 20),
            // Painel Direito: Dados Extraídos
            Expanded(
              flex: 4,
              child: _buildExtractedDataPanel(isReviewed),
            ),
          ],
        );
      },
    );
  }

  /// Painel Esquerdo: Renderização de PDF ou Imagem
  Widget _buildDocumentViewerPanel() {
    final isPdf = document.fileType.toLowerCase() == 'pdf';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Barra de Cabeçalho do Visualizador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceMuted,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Icon(
                  isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                  size: 18,
                  color: isPdf ? const Color(0xFFF87171) : AppTheme.info,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    document.originalName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    document.fileSizeFormatted,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Área de Exibição do Documento
          Expanded(
            child: _buildDocumentViewerContent(isPdf),
          ),
        ],
      ),
    );
  }

  /// Conteúdo do visualizador com suporte a Assets locais (PDF) e URL de imagem
  Widget _buildDocumentViewerContent(bool isPdf) {
    if (isPdf) {
      // Se tem bytes de um PDF recém-enviado pelo usuário, usa os bytes; caso contrário, abre o asset de mock
      if (document.bytes != null && document.bytes!.isNotEmpty) {
        return SfPdfViewer.memory(
          document.bytes!,
          key: ValueKey('pdf_mem_${document.id}'),
          canShowScrollHead: true,
          canShowScrollStatus: true,
          onDocumentLoadFailed: (details) {
            debugPrint('Erro ao carregar PDF (memória): ${details.error} - ${details.description}');
          },
        );
      }

      // Visualização padrão do PDF de mock em assets/mock/desafio.pdf
      return SfPdfViewer.asset(
        document.assetPath ?? 'assets/mock/desafio.pdf',
        key: ValueKey('pdf_asset_${document.id}'),
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoadFailed: (details) {
          debugPrint('Erro ao carregar PDF (asset): ${details.error} - ${details.description}');
        },
      );
    } else {
      // Se tem bytes de uma imagem recém-enviada pelo usuário, usa os bytes
      if (document.bytes != null && document.bytes!.isNotEmpty) {
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Center(
            child: Image.memory(
              document.bytes!,
              fit: BoxFit.contain,
            ),
          ),
        );
      }

      // Imagem padrão de exemplo conforme solicitado
      final imageUrl = document.previewUrl ??
          'https://dummyimage.com/600x400/000/fff.png&text=Exemplo+de+documento';

      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: Center(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackDocPreview();
            },
          ),
        ),
      );
    }
  }

  /// Cartão de demonstração visual estilizado quando o binário bruto não estiver disponível
  Widget _buildFallbackDocPreview() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  size: 40,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                document.originalName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Documento registrado • ${document.fileSizeFormatted}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Formato:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  Text(document.fileType.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Status:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  Text(document.status.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Autenticação:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  Text('#DOC-${document.id.hashCode.abs()}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Painel Direito: Formulário com dados extraídos
  Widget _buildExtractedDataPanel(bool isReviewed) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReviewed ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da Conferência
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.fact_check_outlined,
                      size: 20, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Conferência de Dados',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      'v${document.version}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              _buildStatusChip(document.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isReviewed
                ? 'Este documento já foi conferido e aprovado.'
                : 'Revise e confirme as informações extraídas pela Inteligência Artificial.',
            style: TextStyle(
              fontSize: 12,
              color: isReviewed ? AppTheme.success : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 18),

          // Banner de Processamento de IA (quando ativo)
          if (isProcessing) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Processamento de IA em andamento...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(processingProgress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: processingProgress > 0 ? processingProgress : null,
                      backgroundColor: AppTheme.border,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Extraindo tipologia, data e gerando nome padronizado...',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Campo: Nome Original do Arquivo (Read Only)
          const Text(
            'Nome Original do Arquivo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    document.originalName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Linha: Tipo do Documento (Select) & Data do Documento (dd/MM/yyyy)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo do Documento (Select Predefinido)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Documento *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: ClientFormController.documentTypes.contains(selectedDocumentType)
                          ? selectedDocumentType
                          : ClientFormController.documentTypes.first,
                      items: ClientFormController.documentTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: isReviewed ? null : onDocumentTypeChanged,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined,
                            size: 16, color: AppTheme.textMuted),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      dropdownColor: AppTheme.surface,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Data do Documento (dd/mm/yyyy)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data do Doc. *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: documentDateController,
                      enabled: !isReviewed,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _DateMaskFormatter(),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'dd/mm/aaaa',
                        prefixIcon: Icon(Icons.calendar_today_outlined,
                            size: 16, color: AppTheme.textMuted),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campo: Nome Padronizado Sugerido (Editável)
          Row(
            children: [
              const Text(
                'Nome Padronizado',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Padrão: [TIPO]_[PRIMEIRO_NOME]_[DATA_ENVIO].[ext]',
                child: Icon(Icons.info_outline_rounded,
                    size: 14, color: AppTheme.primary.withValues(alpha: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: standardizedNameController,
            enabled: !isReviewed,
            decoration: const InputDecoration(
              hintText: 'Ex: CONTRATO_JOAO_31_08_2026.pdf',
              prefixIcon: Icon(Icons.auto_fix_high_rounded,
                  size: 16, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),

          // Campo: Observações
          const Text(
            'Observações da IA e do Revisor',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: observationsController,
            enabled: !isReviewed,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Observações sobre assinaturas, legibilidade, etc.',
            ),
          ),
          const SizedBox(height: 24),

          // Barra de Ações do Documento
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Botão Processar com IA (desabilitado se já conferido ou processando)
              Tooltip(
                message: isReviewed
                    ? 'Documento já conferido'
                    : 'Processar e extrair dados via Inteligência Artificial',
                child: OutlinedButton.icon(
                  onPressed: (isProcessing || isReviewed) ? null : onProcessWithAi,
                  icon: const Icon(Icons.psychology_outlined, size: 18),
                  label: const Text('Analisar com IA'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isReviewed ? AppTheme.textMuted : AppTheme.primary,
                    side: BorderSide(
                      color: isReviewed ? AppTheme.border : AppTheme.primary,
                    ),
                  ),
                ),
              ),

              // Botões Excluir e Aprovar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: isReviewed
                        ? 'Documento já conferido e aprovado'
                        : 'Salvar alterações e marcar como Conferido',
                    child: ElevatedButton.icon(
                      onPressed: (isProcessing || isReviewed) ? null : onApprove,
                      icon: Icon(
                        isReviewed
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 18,
                      ),
                      label: Text(
                        isReviewed ? 'Conferido' : 'Aprovar Conferência',
                      ),
                      style: isReviewed
                          ? ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceMuted,
                              foregroundColor: AppTheme.textMuted,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: isProcessing ? null : onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppTheme.danger,
                    hoverColor: AppTheme.dangerBg,
                    tooltip: 'Excluir documento',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(DocumentStatus status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case DocumentStatus.pending:
        bg = AppTheme.warningBg;
        fg = AppTheme.warning;
        icon = Icons.schedule_rounded;
        break;
      case DocumentStatus.uploading:
        bg = AppTheme.infoBg;
        fg = AppTheme.info;
        icon = Icons.cloud_upload_rounded;
        break;
      case DocumentStatus.processing:
        bg = AppTheme.accentSubtle;
        fg = AppTheme.primary;
        icon = Icons.psychology_rounded;
        break;
      case DocumentStatus.awaitingReview:
        bg = AppTheme.warningBg;
        fg = AppTheme.warning;
        icon = Icons.hourglass_top_rounded;
        break;
      case DocumentStatus.reviewed:
        bg = AppTheme.successBg;
        fg = AppTheme.success;
        icon = Icons.check_circle_rounded;
        break;
      case DocumentStatus.error:
        bg = AppTheme.dangerBg;
        fg = AppTheme.danger;
        icon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Formatador de máscara para Data: dd/mm/aaaa
class _DateMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 8; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
