import 'package:desktop_drop/desktop_drop.dart';
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
  final VoidCallback? onRemoveDuplicates;
  final VoidCallback onStartUpload;
  final bool isUploading;

  const DocumentDropzone({
    super.key,
    required this.onFilesSelected,
    required this.queue,
    required this.onRemoveItem,
    required this.onClearQueue,
    this.onRemoveDuplicates,
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
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDuplicates = widget.queue.any((item) => item.isDuplicate);

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
            if (mounted) {
              setState(() {});
            }
          },
          onDragEntered: (_) => setState(() => _isDragging = true),
          onDragExited: (_) => setState(() => _isDragging = false),
          child: InkWell(
            onTap: widget.isUploading ? null : _pickFiles,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: _isDragging
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDragging ? AppTheme.primary : AppTheme.border,
                  width: _isDragging ? 2 : 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isDragging
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : AppTheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isDragging
                            ? AppTheme.primary
                            : AppTheme.border,
                      ),
                    ),
                    child: Icon(
                      _isDragging
                          ? Icons.file_download_outlined
                          : Icons.cloud_upload_outlined,
                      size: 36,
                      color: _isDragging
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Inter',
                        color: AppTheme.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: 'Arraste e solte arquivos aqui ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: 'ou ',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        TextSpan(
                          text: 'clique para selecionar',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Suporta arquivos PDF, Imagens (JPEG, PNG) ou DOCX até 50 MB cada',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Fila de Arquivos Selecionados
        if (widget.queue.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Fila de Upload (${widget.queue.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (hasDuplicates) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.warningBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Duplicata detectada',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  if (hasDuplicates &&
                      widget.onRemoveDuplicates != null &&
                      !widget.isUploading) ...[
                    TextButton.icon(
                      onPressed: widget.onRemoveDuplicates,
                      icon: const Icon(Icons.delete_sweep_outlined,
                          size: 16),
                      label: const Text('Remover Duplicatas'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
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
        color: item.isDuplicate
            ? AppTheme.warningBg.withValues(alpha: 0.25)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isDuplicate ? AppTheme.warning : AppTheme.border,
        ),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.fileName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isDuplicate) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warningBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DUPLICADO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (item.isDuplicate && item.duplicateReason != null)
                  Text(
                    item.duplicateReason!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.warning,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                else
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
            color: item.isDuplicate
                ? AppTheme.warningBg
                : AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            item.isDuplicate ? 'Aviso' : 'Pronto',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: item.isDuplicate
                  ? AppTheme.warning
                  : AppTheme.textSecondary,
            ),
          ),
        );
      case UploadItemStatus.uploading:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            ),
            SizedBox(width: 6),
            Text(
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
