import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/bindings/client_list_binding.dart';
import 'app/core/app_theme.dart';
import 'app/core/routes/app_pages.dart';
import 'app/core/routes/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DocIntelligenceApp());
}

class DocIntelligenceApp extends StatelessWidget {
  const DocIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DOC Intelligence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages,
      initialBinding: ClientListBinding(),
    );
  }
}
