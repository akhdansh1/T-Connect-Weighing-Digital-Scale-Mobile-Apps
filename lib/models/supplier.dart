/// Model untuk Supplier/Vendor
class Supplier {
  final int? id;
  final String supplierCode;
  final String supplierName;
  final String companyName;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String province;
  final String postalCode;
  final String? taxId;
  final String supplierType;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Supplier({
    this.id,
    required this.supplierCode,
    required this.supplierName,
    required this.companyName,
    required this.contactPerson,
    required this.phone,
    this.email = '',
    required this.address,
    required this.city,
    required this.province,
    this.postalCode = '',
    this.taxId,
    this.supplierType = 'Domestic',
    this.isActive = true,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_code': supplierCode,
      'supplier_name': supplierName,
      'company_name': companyName,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'province': province,
      'postal_code': postalCode,
      'tax_id': taxId,
      'supplier_type': supplierType,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      supplierCode: map['supplier_code'] ?? '',
      supplierName: map['supplier_name'] ?? '',
      companyName: map['company_name'] ?? '',
      contactPerson: map['contact_person'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      province: map['province'] ?? '',
      postalCode: map['postal_code'] ?? '',
      taxId: map['tax_id'],
      supplierType: map['supplier_type'] ?? 'Domestic',
      isActive: map['is_active'] == 1,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Supplier copyWith({
    int? id, String? supplierCode, String? supplierName, String? companyName,
    String? contactPerson, String? phone, String? email, String? address,
    String? city, String? province, String? postalCode, String? taxId,
    String? supplierType, bool? isActive, String? notes,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      supplierCode: supplierCode ?? this.supplierCode,
      supplierName: supplierName ?? this.supplierName,
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      taxId: taxId ?? this.taxId,
      supplierType: supplierType ?? this.supplierType,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getFullName() => '$supplierCode - $supplierName';
  String getDisplayName() => '$supplierName ($companyName)';
  String getFullAddress() {
    List<String> parts = [address, city, province];
    if (postalCode.isNotEmpty) parts.add(postalCode);
    return parts.join(', ');
  }

  static const List<String> types = ['Domestic', 'Import', 'Local', 'International'];
}