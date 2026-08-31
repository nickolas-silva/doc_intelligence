import '../domain/models/client_model.dart';
import '../domain/models/paginated_result.dart';

/// Contrato para o repositório de clientes.
///
/// Não deve depender do pacote `get` conforme diretrizes de arquitetura.
abstract class ClientRepository {
  Future<PaginatedResult<ClientModel>> getClients({
    int page = 1,
    int perPage = 10,
    String? search,
  });

  Future<ClientModel> getClientById(String id);

  Future<ClientModel> createClient(ClientModel client);

  Future<ClientModel> updateClient(ClientModel client);

  Future<void> deleteClient(String id);
}
