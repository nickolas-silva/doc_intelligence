import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../controllers/client_list_controller.dart';
import '../core/app_config.dart';
import '../repository/client_repository.dart';
import '../repository/client_repository_impl.dart';
import '../repository/mock_client_repository.dart';

/// Injeção de dependências para a tela de listagem de clientes.
class ClientListBinding extends Bindings {
  @override
  void dependencies() {
    // Configuração do Dio para consumo de API
    Get.lazyPut<Dio>(
      () => Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.requestTimeout,
          receiveTimeout: AppConfig.requestTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ),
      fenix: true,
    );

    // Repositório de clientes (alterna entre Mock em memória e API Mockoon)
    Get.lazyPut<ClientRepository>(
      () {
        if (AppConfig.useMockRepository) {
          return MockClientRepository();
        }
        return ClientRepositoryImpl(dio: Get.find<Dio>());
      },
      fenix: true,
    );

    // Controller da tela de listagem
    Get.lazyPut<ClientListController>(
      () => ClientListController(
        repository: Get.find<ClientRepository>(),
      ),
    );
  }
}
