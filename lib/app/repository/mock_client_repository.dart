import '../domain/models/client_model.dart';
import '../domain/models/paginated_result.dart';
import 'client_repository.dart';

/// Implementação Mock do repositório de clientes com dados fictícios
/// e simulação de latência assíncrona.
///
/// Não deve importar ou depender do pacote `get`.
class MockClientRepository implements ClientRepository {
  final List<ClientModel> _mockClients = [
    ClientModel(
      id: '1',
      name: 'João Fictício da Silva',
      city: 'São Paulo - SP',
      cpf: '123.456.789-00',
      rg: '12.345.678-9',
      totalDocuments: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    ClientModel(
      id: '2',
      name: 'Maria Fictícia de Oliveira',
      city: 'Curitiba - PR',
      cpf: '234.567.890-11',
      rg: '23.456.789-0',
      totalDocuments: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    ClientModel(
      id: '3',
      name: 'Carlos Fictício Pereira',
      city: 'Belo Horizonte - MG',
      cpf: '345.678.901-22',
      rg: '34.567.890-1',
      totalDocuments: 7,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    ClientModel(
      id: '4',
      name: 'Ana Fictícia Souza',
      city: 'Porto Alegre - RS',
      cpf: '456.789.012-33',
      rg: '45.678.901-2',
      totalDocuments: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    ClientModel(
      id: '5',
      name: 'Lucas Fictício Mendes',
      city: 'Rio de Janeiro - RJ',
      cpf: '567.890.123-44',
      rg: '56.789.012-3',
      totalDocuments: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    ClientModel(
      id: '6',
      name: 'Beatriz Fictícia Lima',
      city: 'Salvador - BA',
      cpf: '678.901.234-55',
      rg: '67.890.123-4',
      totalDocuments: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ClientModel(
      id: '7',
      name: 'Fernando Fictício Ribeiro',
      city: 'Recife - PE',
      cpf: '789.012.345-66',
      rg: '78.901.234-5',
      totalDocuments: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    ClientModel(
      id: '8',
      name: 'Juliana Fictícia Castro',
      city: 'Florianópolis - SC',
      cpf: '890.123.456-77',
      rg: '89.012.345-6',
      totalDocuments: 6,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ClientModel(
      id: '9',
      name: 'Rafael Fictício Duarte',
      city: 'Fortaleza - CE',
      cpf: '901.234.567-88',
      rg: '90.123.456-7',
      totalDocuments: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ClientModel(
      id: '10',
      name: 'Camila Fictícia Barbosa',
      city: 'Goiânia - GO',
      cpf: '012.345.678-99',
      rg: '01.234.567-8',
      totalDocuments: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ClientModel(
      id: '11',
      name: 'Marcos Fictício Alencar',
      city: 'Vitória - ES',
      cpf: '111.222.333-44',
      rg: '11.222.333-4',
      totalDocuments: 8,
      createdAt: DateTime.now().subtract(const Duration(hours: 14)),
    ),
    ClientModel(
      id: '12',
      name: 'Patrícia Fictícia Moreira',
      city: 'Manaus - AM',
      cpf: '222.333.444-55',
      rg: '22.333.444-5',
      totalDocuments: 1,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  @override
  Future<PaginatedResult<ClientModel>> getClients({
    int page = 1,
    int perPage = 10,
    String? search,
  }) async {
    // Simula a latência de rede/processamento
    await Future.delayed(const Duration(milliseconds: 650));

    var filtered = List<ClientModel>.from(_mockClients);

    if (search != null && search.trim().isNotEmpty) {
      final query = search.trim().toLowerCase();
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.city.toLowerCase().contains(query) ||
            c.cpf.contains(query) ||
            c.rg.contains(query);
      }).toList();
    }

    final totalCount = filtered.length;
    final startIndex = (page - 1) * perPage;
    
    if (startIndex >= totalCount) {
      return PaginatedResult(
        items: [],
        totalCount: totalCount,
        page: page,
        perPage: perPage,
      );
    }

    final endIndex = (startIndex + perPage > totalCount) ? totalCount : (startIndex + perPage);
    final pageItems = filtered.sublist(startIndex, endIndex);

    return PaginatedResult(
      items: pageItems,
      totalCount: totalCount,
      page: page,
      perPage: perPage,
    );
  }

  @override
  Future<ClientModel> getClientById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final client = _mockClients.cast<ClientModel?>().firstWhere(
          (c) => c?.id == id,
          orElse: () => null,
        );

    if (client == null) {
      throw Exception('Cliente não encontrado');
    }
    return client;
  }

  @override
  Future<ClientModel> createClient(ClientModel client) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newClient = client.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
    );
    _mockClients.insert(0, newClient);
    return newClient;
  }

  @override
  Future<ClientModel> updateClient(ClientModel client) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockClients.indexWhere((c) => c.id == client.id);
    if (index == -1) {
      throw Exception('Cliente não encontrado para atualização');
    }
    final updated = client.copyWith(updatedAt: DateTime.now());
    _mockClients[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteClient(String id) async {
    await Future.delayed(const Duration(milliseconds: 450));
    _mockClients.removeWhere((c) => c.id == id);
  }
}
