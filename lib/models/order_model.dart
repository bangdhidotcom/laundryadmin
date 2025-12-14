class Order {
  final String? id;
  final String customerName;
  final String serviceType;
  final double totalCost;
  final String address;
  final DateTime orderDate;
  final String status;
  final String? notes;
  final int? outletId;
  final String? userId;

  final double? latitude;
  final double? longitude;
  final String deliveryType;
  final double deliveryFee;
  final String deliveryStatus;
  final String? proofPhotoUrl;

  Order({
    this.id,
    required this.customerName,
    required this.serviceType,
    required this.totalCost,
    required this.address,
    required this.orderDate,
    this.status = 'pending',
    this.notes,
    this.latitude,
    this.longitude,
    this.deliveryType = 'Reguler',
    this.deliveryFee = 0,
    this.deliveryStatus = 'pending',
    this.proofPhotoUrl,
    this.outletId,
    this.userId,
  });

  bool get isPickup => status.toLowerCase() == 'pickup';
  bool get isDelivery => status.toLowerCase() == 'delivery';

  Map<String, dynamic> toMap() {
    return {
      'customer_name': customerName,
      'service_type': serviceType,
      'total_cost': totalCost,
      'address': address,
      'order_date': orderDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'delivery_type': deliveryType,
      'delivery_fee': deliveryFee,
      'delivery_status': deliveryStatus,
      'outlet_id': outletId,
      'user_id': userId,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, String docId) {
    return Order(
      id: docId,
      customerName: map['customer_name'] ?? '',
      serviceType: map['service_type'] ?? '',
      totalCost: (map['total_cost'] ?? 0).toDouble(),
      address: map['address'] ?? '',
      orderDate: DateTime.parse(
        map['order_date'] ?? DateTime.now().toIso8601String(),
      ),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      deliveryType: map['delivery_type'] ?? 'Reguler',
      deliveryFee: (map['delivery_fee'] ?? 0).toDouble(),
      deliveryStatus: map['delivery_status'] ?? 'pending',
      proofPhotoUrl: map['pickup_proof_url'] ?? map['delivery_proof_url'],
      outletId: map['outlet_id'] as int?,
      userId: map['user_id']?.toString(),
    );
  }
}