class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int perPage;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.perPage,
  });

  int get totalPages => totalCount == 0 ? 1 : (totalCount / perPage).ceil();
  bool get hasPreviousPage => page > 1;
  bool get hasNextPage => page < totalPages;
}
