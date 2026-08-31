import 'package:dio/dio.dart';
import '../domain/models/client_model.dart';
import '../domain/models/paginated_result.dart';
import 'client_repository.dart';

/// Implementação do repositório consumindo a API REST (Mockoon / Back-end) via Dio.
///
/// Não deve importar ou depender do pacote `get`.
class ClientRepositoryImpl implements ClientRepository {
  final Dio dio;

  ClientRepositoryImpl({required this.dio});

  @override
  Future<PaginatedResult<ClientModel>> getClients({
    int page = 1,
    int perPage = 10,
    String? search,
  }) async {
    try {
      final response = await dio.get(
        '/clients',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final data = response.data;
      List<ClientModel> items = [];
      int totalCount = 0;

      if (data is Map<String, dynamic>) {
        final rawList = data['data'] ?? data['items'] ?? [];
        if (rawList is List) {
          items = rawList
              .map((item) => ClientModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        totalCount = data['total'] ?? data['total_count'] ?? items.length;
      } else if (data is List) {
        items = data
            .map((item) => ClientModel.fromJson(item as Map<String, dynamic>))
            .toList();
        totalCount = items.length;
      }

      return PaginatedResult<ClientModel>(
        items: items,
        totalCount: totalCount,
        page: page,
        perPage: perPage,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Falha ao carregar lista de clientes: $e');
    }
  }

  @override
  Future<ClientModel> getClientById(String id) async {
    try {
      final response = await dio.get('/clients/$id');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final clientData = data['data'] ?? data;
        return ClientModel.fromJson(clientData as Map<String, dynamic>);
      }
      throw Exception('Formato de resposta inválido');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ClientModel> createClient(ClientModel client) async {
    try {
      final response = await dio.post(
        '/clients',
        data: client.toJson(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final clientData = data['data'] ?? data;
        return ClientModel.fromJson(clientData as Map<String, dynamic>);
      }
      return client;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ClientModel> updateClient(ClientModel client) async {
    try {
      final response = await dio.put(
        '/clients/${client.id}',
        data: client.toJson(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final clientData = data['data'] ?? data;
        return ClientModel.fromJson(clientData as Map<String, dynamic>);
      }
      return client;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteClient(String id) async {
    try {
      await dio.delete('/clients/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    if (error.response?.statusCode == 409) {
      return ConflictException('Este registro está em conflito de concorrência.');
    }
    if (error.response?.statusCode == 404) {
      return NotFoundException('Cliente não encontrado.');
    }
    return Exception(
      error.response?.data?['message'] ??
          error.message ??
          'Ocorreu um erro na comunicação com o servidor.',
    );
  }
}

class ConflictException implements Exception {
  final String message;
  ConflictException(this.message);

  @override
  String toString() => message;
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);

  @override
  String toString() => message;
}
