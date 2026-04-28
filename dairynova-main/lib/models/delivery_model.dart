class Delivery {
  final String id;
  final String customerName;
  final String address;
  final String status; // 'pending', 'picked', 'delivered'
  final bool isEmergency;
  final double lat;
  final double lng;
  final double totalAmount; // Added this to handle the price safely

  Delivery({
    required this.id,
    required this.customerName,
    required this.address,
    required this.status,
    required this.isEmergency,
    required this.lat,
    required this.lng,
    this.totalAmount = 0.0,
  });

  // --- THE FIX: Safe Factory Method ---
  // This method checks the types before assigning them.
  factory Delivery.fromFirestore(String id, Map<String, dynamic> data) {
    return Delivery(
      id: id,
      customerName: data['customerName'] ?? "Unknown Customer",
      address: data['address'] ?? "No Address",
      status: data['status'] ?? "pending",

      // Safety check for boolean
      isEmergency: data['isEmergency'] is bool ? data['isEmergency'] : false,

      // Safety check for lat/lng (This is likely where your double error was!)
      lat: _convertToDouble(data['lat']),
      lng: _convertToDouble(data['lng']),

      // Safety check for the price/totalAmount
      totalAmount: _convertToDouble(data['totalAmount'] ?? data['total']),
    );
  }

  // Helper function to handle the "bool vs double" problem
  static double _convertToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    // If it's a bool or anything else, return 0.0 instead of crashing
    return 0.0;
  }
}
