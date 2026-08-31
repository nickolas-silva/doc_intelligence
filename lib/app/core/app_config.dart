/// Configurações gerais da aplicação e chave de alternância de repositório.
class AppConfig {
  /// Alterna entre o repositório Mock em memória e a API Mockoon (Dio).
  ///
  /// Defina como `false` para consumir a API Mockoon via HTTP.
  /// Defina como `true` para usar o mock local em memória imediatamente.
  static bool useMockRepository = true;

  /// URL base do Mockoon ou serviço de API local
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';

  /// Timeout padrão para requisições
  static const Duration requestTimeout = Duration(seconds: 15);
}
