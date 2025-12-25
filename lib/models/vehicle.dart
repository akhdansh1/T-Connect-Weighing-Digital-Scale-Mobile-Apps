/// Model untuk Vehicle (Kendaraan)
class Vehicle {
  final int? id;
  final String vehicleNumber;
  final String vehicleType;
  final String? driverName;
  final String? driverPhone;
  final String? driverLicense;
  final double? tareWeight;
  final String? company;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Vehicle({
    this.id,
    required this.vehicleNumber,
    required this.vehicleType,
    this.driverName,
    this.driverPhone,
    this.driverLicense,
    this.tareWeight,
    this.company,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_number': vehicleNumber,
      'vehicle_type': vehicleType,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'driver_license': driverLicense,
      'tare_weight': tareWeight,
      'company': company,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'],
      vehicleNumber: map['vehicle_number'] ?? '',
      vehicleType: map['vehicle_type'] ?? 'Truck',
      driverName: map['driver_name'],
      driverPhone: map['driver_phone'],
      driverLicense: map['driver_license'],
      tareWeight: map['tare_weight']?.toDouble(),
      company: map['company'],
      isActive: map['is_active'] == 1,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Vehicle copyWith({
    int? id, String? vehicleNumber, String? vehicleType,
    String? driverName, String? driverPhone, String? driverLicense,
    double? tareWeight, String? company, bool? isActive, String? notes,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverLicense: driverLicense ?? this.driverLicense,
      tareWeight: tareWeight ?? this.tareWeight,
      company: company ?? this.company,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getDisplayName() {
    if (driverName != null && driverName!.isNotEmpty) {
      return '$vehicleNumber - $driverName';
    }
    return vehicleNumber;
  }

  String getFullInfo() {
    List<String> parts = [vehicleNumber, vehicleType];
    if (driverName != null && driverName!.isNotEmpty) parts.add('Driver: $driverName');
    if (company != null && company!.isNotEmpty) parts.add('($company)');
    return parts.join(' - ');
  }

  bool get hasTareWeight => tareWeight != null && tareWeight! > 0;

  static const List<String> types = [
    'Truck', 'Pickup', 'Van',
    'Container 20ft', 'Container 40ft',
    'Trailer', 'Tanker', 'Box Truck', 'Flatbed', 'Other',
  ];
}