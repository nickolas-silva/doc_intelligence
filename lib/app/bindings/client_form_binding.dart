import 'package:get/get.dart';

import '../controllers/client_form_controller.dart';
import '../repository/client_repository.dart';
import '../repository/document_repository.dart';
import '../repository/mock_document_repository.dart';

/// Injeção de dependências para o formulário de cliente e documentos.
class ClientFormBinding extends Bindings {
  @override
  void dependencies() {
    // Repositório de documentos
    Get.lazyPut<DocumentRepository>(
      () => MockDocumentRepository(),
      fenix: true,
    );

    // Controller do formulário com as dependências necessárias
    Get.lazyPut<ClientFormController>(
      () => ClientFormController(
        clientRepository: Get.find<ClientRepository>(),
        documentRepository: Get.find<DocumentRepository>(),
      ),
    );
  }
}
