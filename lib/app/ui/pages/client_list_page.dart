import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/client_list_controller.dart';
import '../../core/app_theme.dart';
import '../widgets/custom_datatable.dart';
import '../widgets/datatable_pagination_bar.dart';
import '../widgets/summary_stat_card.dart';
import '../widgets/table_skeleton_loader.dart';

/// Tela principal de listagem de clientes (Datatable).
class ClientListPage extends GetView<ClientListController> {
  const ClientListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Barra Superior / Header Global do Sistema
            _buildTopNavBar(),

            // Conteúdo Principal com Scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header da Página com Título e Ação de Novo Cliente
                        _buildPageHeader(),
                        const SizedBox(height: 24),

                        // Métricas Rápidas
                        _buildMetricsRow(),
                        const SizedBox(height: 24),

                        // Painel Principal: Filtros + Datatable
                        _buildDatatableCard(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra superior institucional com logo
  Widget _buildTopNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Row(
        children: [
          // Marca / Título do Sistema
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Color(0xFF0E0E10),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DOC Intelligence',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'Inteligência Documental Jurídica',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Cabeçalho da página com título e botão de ação
  Widget _buildPageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        return isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Clientes Cadastrados',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gerencie os clientes e acesse os fluxos de conferência e upload de documentos.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: controller.openNewClientForm,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Novo Cliente'),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clientes Cadastrados',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Gerencie os clientes e acesse os fluxos de conferência e upload de documentos.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: controller.openNewClientForm,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Novo Cliente'),
                  ),
                ],
              );
      },
    );
  }

  /// Métricas e contadores rápidos
  Widget _buildMetricsRow() {
    return Obx(() {
      final totalClients = controller.totalCount.value;
      final totalDocs = controller.clients.fold<int>(
        0,
        (acc, curr) => acc + curr.totalDocuments,
      );

      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 750;

          final card1 = SummaryStatCard(
            title: 'Total de Clientes',
            value: '$totalClients',
            subtitle: 'Clientes ativos na base',
            icon: Icons.people_alt_outlined,
            iconColor: AppTheme.accent,
            iconBgColor: AppTheme.accentSubtle,
          );

          final card2 = SummaryStatCard(
            title: 'Documentos na Página',
            value: '$totalDocs',
            subtitle: 'Vinculados aos clientes listados',
            icon: Icons.folder_shared_outlined,
            iconColor: AppTheme.success,
            iconBgColor: AppTheme.successBg,
          );

          if (isNarrow) {
            return Column(
              children: [
                card1,
                const SizedBox(height: 12),
                card2,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: 16),
              Expanded(child: card2),
            ],
          );
        },
      );
    });
  }

  /// Card principal contendo a barra de busca e a tabela
  Widget _buildDatatableCard(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de Filtros e Busca
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Campo de Busca
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: controller.searchInputController,
                      onChanged: controller.onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nome ou cidade...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: AppTheme.textMuted,
                        ),
                        suffixIcon: Obx(() {
                          if (controller.searchQuery.value.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            color: AppTheme.textSecondary,
                            onPressed: controller.clearSearch,
                          );
                        }),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Botão de Atualizar / Refresh
                IconButton(
                  onPressed: () => controller.fetchClients(),
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppTheme.textSecondary,
                  tooltip: 'Recarregar dados',
                ),
              ],
            ),
          ),

          // Divisor
          const Divider(height: 1, color: AppTheme.border),

          // Tabela ou Estados (Loading, Empty, Error)
          Obx(() {
            if (controller.isLoading.value) {
              return const TableSkeletonLoader(rowCount: 6);
            }

            if (controller.errorMessage.value != null && controller.clients.isEmpty) {
              return _buildErrorState();
            }

            if (controller.clients.isEmpty) {
              return _buildEmptyState();
            }

            return CustomDatatable(
              clients: controller.clients,
              onViewDocuments: controller.openClientDetail,
              onEdit: controller.editClient,
              onDelete: controller.confirmDeleteClient,
            );
          }),

          // Barra de Paginação
          Obx(() {
            return DatatablePaginationBar(
              currentPage: controller.currentPage.value,
              totalPages: controller.totalPages.value,
              totalCount: controller.totalCount.value,
              perPage: controller.perPage.value,
              isLoading: controller.isLoading.value,
              onPerPageChanged: controller.setPerPage,
              onPreviousPage: controller.previousPage,
              onNextPage: controller.nextPage,
            );
          }),
        ],
      ),
    );
  }

  /// Estado de Erro com botão de retry
  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.dangerBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.danger,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Não foi possível carregar os clientes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => controller.fetchClients(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  /// Estado Vazio
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: AppTheme.textMuted,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum cliente encontrado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tente ajustar o termo da busca ou adicione um novo cliente.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            if (controller.searchQuery.value.isNotEmpty)
              OutlinedButton.icon(
                onPressed: controller.clearSearch,
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: const Text('Limpar Busca'),
              ),
          ],
        ),
      ),
    );
  }
}
