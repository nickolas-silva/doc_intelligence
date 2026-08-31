import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/routes/app_routes.dart';
import '../domain/models/client_model.dart';
import '../repository/client_repository.dart';
import '../repository/client_repository_impl.dart';

/// Controlador responsável pelo gerenciamento de estado da listagem de clientes.
class ClientListController extends GetxController {
  final ClientRepository repository;

  ClientListController({required this.repository});

  // Estados de Dados e UI
  final RxList<ClientModel> clients = <ClientModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  // Paginação e Filtro
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalCount = 0.obs;
  final RxInt perPage = 10.obs;
  final RxString searchQuery = ''.obs;

  // Controller do campo de texto de busca
  final TextEditingController searchInputController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Debounce na busca para evitar requisições excessivas
    debounce(
      searchQuery,
      (_) => fetchClients(page: 1),
      time: const Duration(milliseconds: 400),
    );
    fetchClients();
  }



  /// Busca os clientes de forma paginada e com tratamento de exceções
  Future<void> fetchClients({int? page}) async {
    final targetPage = page ?? currentPage.value;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await repository.getClients(
        page: targetPage,
        perPage: perPage.value,
        search: searchQuery.value,
      );

      clients.assignAll(result.items);
      currentPage.value = result.page;
      totalCount.value = result.totalCount;
      totalPages.value = result.totalPages;
    } on ConflictException catch (e) {
      errorMessage.value = e.message;
      Get.snackbar(
        'Conflito de Atendimento',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber.shade900,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      );
    } catch (e) {
      final message = e.toString().replaceAll('Exception:', '').trim();
      errorMessage.value = message;
      Get.snackbar(
        'Erro ao Carregar Clientes',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Altera a quantidade de itens por página
  void setPerPage(int newPerPage) {
    if (perPage.value == newPerPage) return;
    perPage.value = newPerPage;
    fetchClients(page: 1);
  }

  /// Navega para a página anterior
  void previousPage() {
    if (currentPage.value > 1 && !isLoading.value) {
      fetchClients(page: currentPage.value - 1);
    }
  }

  /// Navega para a próxima página
  void nextPage() {
    if (currentPage.value < totalPages.value && !isLoading.value) {
      fetchClients(page: currentPage.value + 1);
    }
  }

  /// Atualiza o termo de busca
  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  /// Limpa a busca e reseta para a primeira página
  void clearSearch() {
    searchInputController.clear();
    searchQuery.value = '';
    fetchClients(page: 1);
  }

  /// Ação para abrir os detalhes e documentos do cliente
  void openClientDetail(ClientModel client) {
    Get.toNamed(AppRoutes.clientDetails, arguments: client);
  }

  /// Ação para cadastrar novo cliente
  void openNewClientForm() {
    Get.toNamed(AppRoutes.clientForm);
  }

  /// Ação para editar dados do cliente
  void editClient(ClientModel client) {
    Get.toNamed(AppRoutes.clientForm, arguments: client);
  }

  /// Confirmação e exclusão de cliente
  Future<void> confirmDeleteClient(ClientModel client) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Excluir Cliente'),
        content: Text(
          'Deseja realmente remover o cliente "${client.name}"? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteClient(client.id);
    }
  }

  Future<void> _deleteClient(String id) async {
    try {
      await repository.deleteClient(id);
      Get.snackbar(
        'Sucesso',
        'Cliente removido com sucesso.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      );
      fetchClients();
    } on ConflictException catch (e) {
      Get.snackbar(
        'Ação Bloqueada',
        'Conflito: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber.shade900,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Erro ao Excluir',
        'Não foi possível excluir o cliente: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}
