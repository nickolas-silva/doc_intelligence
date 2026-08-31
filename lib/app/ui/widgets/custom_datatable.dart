import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../domain/models/client_model.dart';

/// Tabela de clientes estilizada com suporte a ordenação visual, hover e ações.
class CustomDatatable extends StatelessWidget {
  final List<ClientModel> clients;
  final Function(ClientModel) onViewDocuments;
  final Function(ClientModel) onEdit;
  final Function(ClientModel) onDelete;

  const CustomDatatable({
    super.key,
    required this.clients,
    required this.onViewDocuments,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(850.0, constraints.maxWidth);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                // Cabeçalho da Tabela
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.border),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'CLIENTE / NOME',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'CPF',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'RG',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'CIDADE / UF',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'DOCUMENTOS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'AÇÕES',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Linhas de Clientes
                ...clients.map((client) => _ClientRow(
                      client: client,
                      onViewDocuments: () => onViewDocuments(client),
                      onEdit: () => onEdit(client),
                      onDelete: () => onDelete(client),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ClientRow extends StatefulWidget {
  final ClientModel client;
  final VoidCallback onViewDocuments;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClientRow({
    required this.client,
    required this.onViewDocuments,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ClientRow> createState() => _ClientRowState();
}

class _ClientRowState extends State<_ClientRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final client = widget.client;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.surfaceMuted.withValues(alpha: 0.5) : AppTheme.surface,
          border: const Border(
            bottom: BorderSide(color: AppTheme.border),
          ),
        ),
        child: Row(
          children: [
            // Nome + Avatar Fictício
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.accentSubtle,
                    child: Text(
                      client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: #${client.id}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // CPF
            Expanded(
              flex: 2,
              child: Text(
                client.cpf,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ),

            // RG
            Expanded(
              flex: 2,
              child: Text(
                client.rg,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),

            // Cidade
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      client.city,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Quantidade de Documentos
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: client.totalDocuments > 0
                        ? AppTheme.accentSubtle
                        : AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: client.totalDocuments > 0
                          ? AppTheme.accent.withValues(alpha: 0.2)
                          : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 13,
                        color: client.totalDocuments > 0
                            ? AppTheme.accent
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${client.totalDocuments} doc${client.totalDocuments == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: client.totalDocuments > 0
                              ? AppTheme.accent
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Ações
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Ação principal: Carregar / Ver Documentos (Split View)
                  Tooltip(
                    message: 'Ver e Enviar Documentos',
                    child: InkWell(
                      onTap: widget.onViewDocuments,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_open_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Docs',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Ação secundária: Editar Dados do Cliente
                  Tooltip(
                    message: 'Editar Cliente',
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: AppTheme.textSecondary,
                      hoverColor: AppTheme.surfaceMuted,
                      splashRadius: 18,
                      onPressed: widget.onEdit,
                    ),
                  ),

                  // Ação terciária: Excluir
                  Tooltip(
                    message: 'Excluir',
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      color: AppTheme.danger,
                      hoverColor: AppTheme.dangerBg,
                      splashRadius: 18,
                      onPressed: widget.onDelete,
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
}
