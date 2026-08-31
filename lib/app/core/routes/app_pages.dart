import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../bindings/client_list_binding.dart';
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
    // Placeholder para as próximas etapas (Cadastro/Edição e Split View de Documentos)
    GetPage(
      name: AppRoutes.clientForm,
      page: () => Scaffold(
        appBar: AppBar(title: const Text('Formulário de Cliente')),
        body: const Center(
          child: Text('Formulário de cadastro/edição (Próxima etapa)'),
        ),
      ),
    ),
    GetPage(
      name: AppRoutes.clientDetails,
      page: () => Scaffold(
        appBar: AppBar(title: const Text('Documentos do Cliente')),
        body: const Center(
          child: Text('Split View e Upload em Lote (Próxima etapa)'),
        ),
      ),
    ),
  ];
}
