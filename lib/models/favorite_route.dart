class FavoriteRoute {
  int? id;

  String startAddress;
  String endAddress;

  String transportMode;

  FavoriteRoute({
    this.id,
    required this.startAddress,
    required this.endAddress,
    required this.transportMode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startAddress': startAddress,
      'endAddress': endAddress,
      'transportMode': transportMode,
    };
  }
}
