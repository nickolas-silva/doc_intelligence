import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../controllers/client_form_controller.dart';
import '../../core/app_theme.dart';

/// Área de Dropzone e File Picker para upload de documentos (único ou em lote).
class DocumentDropzone extends StatefulWidget {
  final Function(List<DocumentUploadItem>) onFilesSelected;
  final List<DocumentUploadItem> queue;
  final Function(int) onRemoveItem;
  final VoidCallback onClearQueue;
  final VoidCallback onStartUpload;
  final bool isUploading;

  const DocumentDropzone({
    super.key,
    required this.onFilesSelected,
    required this.queue,
    required this.onRemoveItem,
    required this.onClearQueue,
    required this.onStartUpload,
    required this.isUploading,
  });

  @override
  State<DocumentDropzone> createState() => _DocumentDropzoneState();
}

class _DocumentDropzoneState extends State<DocumentDropzone> {
  bool _isDragging = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'docx'],
    );

    if (result != null && result.files.isNotEmpty) {
      final items = result.files.map((file) {
        return DocumentUploadItem(
          fileName: file.name,
          fileSizeBytes: file.size,
          bytes: file.bytes,
          status: UploadItemStatus.queued,
        );
      }).toList();

      widget.onFilesSelected(items);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dropzone interativo
        DropTarget(
          onDragDone: (detail) async {
            final items = <DocumentUploadItem>[];
            for (final file in detail.files) {
              final bytes = await file.readAsBytes();
              items.add(
                DocumentUploadItem(
                  fileName: file.name,
                  fileSizeBytes: bytes.length,
                  bytes: bytes,
                  status: UploadItemStatus.queued,
                ),
              );
            }
            widget.onFilesSelected(items);
          },
          onDragEntered: (_) => setState(() => _isDragging = true),
          onDragExited: (_) => setState(() => _isDragging = false),
          child: InkWell(
            onTap: widget.isUploading ? null : _pickFiles,
            borderRadius: BorderRadius.circular(16),
            child: DottedBorder(
              color: _isDragging ? AppTheme.accentLight : AppTheme.primary,
              strokeWidth: 2,
              dashPattern: const [8, 6],
              borderType: BorderType.RRect,
              radius: const Radius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: _isDragging
                      ? AppTheme.accentSubtle
                      : AppTheme.surfaceMuted.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
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
                      child: Icon(
                        _isDragging
                            ? Icons.file_download_outlined
                            : Icons.cloud_upload_outlined,
                        color: AppTheme.primary,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Arraste e solte seus documentos aqui',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ou clique para selecionar do computador (suporta seleção múltipla)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Text(
                        'Formatos suportados: PDF, JPEG, PNG, DOCX (até 25MB)',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Lista da Fila de Upload
        if (widget.queue.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fila de Upload (${widget.queue.length} ${widget.queue.length == 1 ? 'arquivo' : 'arquivos'})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (!widget.isUploading)
                TextButton.icon(
                  onPressed: widget.onClearQueue,
                  icon: const Icon(Icons.clear_all_rounded, size: 16),
                  label: const Text('Limpar Fila'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.queue.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = widget.queue[index];
              return _UploadQueueItemTile(
                item: item,
                onRemove: widget.isUploading
                    ? null
                    : () => widget.onRemoveItem(index),
              );
            },
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: widget.isUploading ? null : widget.onStartUpload,
              icon: widget.isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0E0E10),
                      ),
                    )
                  : const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(
                widget.isUploading
                    ? 'Enviando Documentos...'
                    : 'Enviar ${widget.queue.length} ${widget.queue.length == 1 ? 'Documento' : 'Documentos'}',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _UploadQueueItemTile extends StatelessWidget {
  final DocumentUploadItem item;
  final VoidCallback? onRemove;

  const _UploadQueueItemTile({
    required this.item,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData = Icons.insert_drive_file_outlined;
    Color iconColor = AppTheme.textSecondary;
    final ext = item.fileName.split('.').last.toLowerCase();

    if (ext == 'pdf') {
      iconData = Icons.picture_as_pdf_outlined;
      iconColor = const Color(0xFFF87171);
    } else if (['jpg', 'jpeg', 'png'].contains(ext)) {
      iconData = Icons.image_outlined;
      iconColor = AppTheme.info;
    }

    return Container(
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
                  item.fileName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.fileSizeFormatted,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildStatusBadge(),
          if (onRemove != null && item.status == UploadItemStatus.queued) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16),
              color: AppTheme.textMuted,
              hoverColor: AppTheme.dangerBg,
              onPressed: onRemove,
              tooltip: 'Remover da fila',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    switch (item.status) {
      case UploadItemStatus.queued:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Pronto',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        );
      case UploadItemStatus.uploading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Enviando...',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        );
      case UploadItemStatus.done:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.successBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Enviado',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.success,
            ),
          ),
        );
      case UploadItemStatus.error:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.dangerBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            item.errorMessage ?? 'Erro',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.danger,
            ),
          ),
        );
    }
  }
}
