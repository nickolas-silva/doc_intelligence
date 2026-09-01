/// Exceção lançada quando ocorre concorrência de atualização (HTTP 409 Conflict)
class ConflictException implements Exception {
  final String message;
  final dynamic latestData;
  final dynamic latestDocument;

  const ConflictException(
    this.message, {
    this.latestData,
    this.latestDocument,
  });

  @override
  String toString() => message;
}

/// Exceção para recursos não encontrados (HTTP 404)
class NotFoundException implements Exception {
  final String message;

  const NotFoundException(this.message);

  @override
  String toString() => message;
}
