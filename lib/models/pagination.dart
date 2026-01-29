class PaginationModel<T> {
  List<T> nodes;
  bool hasNextPage;
  String? endCursor;

  PaginationModel({
    required this.nodes,
    required this.hasNextPage,
    required this.endCursor,
  });

  factory PaginationModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) map,
  ) {
    // Handle both flat (if any) and nested pageInfo structures
    final pageInfo = json['pageInfo'] as Map<String, dynamic>?;
    final hasNextPage = pageInfo != null 
        ? pageInfo['hasNextPage'] as bool 
        : (json['hasNextPage'] as bool? ?? false);
    final endCursor = pageInfo != null 
        ? pageInfo['endCursor'] as String? 
        : (json['endCursor'] as String?);

    return PaginationModel(
      nodes: (json['nodes'] as List)
          .cast<Map<String, dynamic>>()
          .map(map)
          .toList(),
      hasNextPage: hasNextPage,
      endCursor: endCursor,
    );
  }
}
