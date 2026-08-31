import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

/// Barra inferior de paginação para o Datatable.
class DatatablePaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int perPage;
  final bool isLoading;
  final Function(int) onPerPageChanged;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  const DatatablePaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.perPage,
    required this.isLoading,
    required this.onPerPageChanged,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    final start = totalCount == 0 ? 0 : ((currentPage - 1) * perPage) + 1;
    final end = (currentPage * perPage > totalCount) ? totalCount : (currentPage * perPage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.border),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final perPageSection = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Linhas:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: perPage,
                    focusNode: FocusNode(canRequestFocus: false),
                    icon: const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.textSecondary),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    items: [5, 10, 20, 50].map((val) {
                      return DropdownMenuItem<int>(
                        value: val,
                        child: Text('$val'),
                      );
                    }).toList(),
                    onChanged: isLoading ? null : (v) => v != null ? onPerPageChanged(v) : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$start - $end de $totalCount',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          );

          final paginationControls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pág. $currentPage de $totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                color: AppTheme.textPrimary,
                disabledColor: AppTheme.textMuted,
                splashRadius: 18,
                onPressed: (currentPage > 1 && !isLoading) ? onPreviousPage : null,
                tooltip: 'Página Anterior',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                color: AppTheme.textPrimary,
                disabledColor: AppTheme.textMuted,
                splashRadius: 18,
                onPressed: (currentPage < totalPages && !isLoading) ? onNextPage : null,
                tooltip: 'Próxima Página',
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                perPageSection,
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: paginationControls,
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              perPageSection,
              paginationControls,
            ],
          );
        },
      ),
    );
  }
}
