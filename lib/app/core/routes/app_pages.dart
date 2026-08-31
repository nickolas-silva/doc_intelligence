import 'package:get/get.dart';

import '../../bindings/client_form_binding.dart';
import '../../bindings/client_list_binding.dart';
import '../../ui/pages/client_form_page.dart';
import '../../ui/pages/client_list_page.dart';
import 'app_routes.dart';

/// Configuração de rotas e páginas da aplicação GetX.
abstract class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.home,
      page: () => const ClientListPage(),
      binding: ClientListBinding(),
    ),
    GetPage(
      name: AppRoutes.clientForm,
      page: () => const ClientFormPage(),
      binding: ClientFormBinding(),
    ),
    GetPage(
      name: AppRoutes.clientDetails,
      page: () => const ClientFormPage(),
      binding: ClientFormBinding(),
    ),
  ];
}
