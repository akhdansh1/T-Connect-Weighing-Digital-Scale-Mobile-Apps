class CompanyInfo {
  final int? id;
  final String companyName;
  final String companyId;
  final String address;
  final String address2;
  final String city;
  final String province;
  final String postalCode;
  final String phone;
  final String fax;
  final String email;
  final String website;
  final String department;
  final String? logoPath;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CompanyInfo({
    this.id,
    required this.companyName,
    required this.companyId,
    required this.address,
    this.address2 = '',
    required this.city,
    required this.province,
    required this.postalCode,
    required this.phone,
    this.fax = '',
    required this.email,
    this.website = '',
    this.department = 'Production',
    this.logoPath,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'company_id': companyId,
      'address': address,
      'address2': address2,
      'city': city,
      'province': province,
      'postal_code': postalCode,
      'phone': phone,
      'fax': fax,
      'email': email,
      'website': website,
      'department': department,
      'logo_path': logoPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      id: map['id'],
      companyName: map['company_name'] ?? '',
      companyId: map['company_id'] ?? '',
      address: map['address'] ?? '',
      address2: map['address2'] ?? '',
      city: map['city'] ?? '',
      province: map['province'] ?? '',
      postalCode: map['postal_code'] ?? '',
      phone: map['phone'] ?? '',
      fax: map['fax'] ?? '',
      email: map['email'] ?? '',
      website: map['website'] ?? '',
      department: map['department'] ?? 'Production',
      logoPath: map['logo_path'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  CompanyInfo copyWith({
    int? id,
    String? companyName,
    String? companyId,
    String? address,
    String? address2,
    String? city,
    String? province,
    String? postalCode,
    String? phone,
    String? fax,
    String? email,
    String? website,
    String? department,
    String? logoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyInfo(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      companyId: companyId ?? this.companyId,
      address: address ?? this.address,
      address2: address2 ?? this.address2,
      city: city ?? this.city,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      phone: phone ?? this.phone,
      fax: fax ?? this.fax,
      email: email ?? this.email,
      website: website ?? this.website,
      department: department ?? this.department,
      logoPath: logoPath ?? this.logoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getFullAddress() {
    List<String> parts = [address];
    if (address2.isNotEmpty) parts.add(address2);
    parts.add(city);
    parts.add(province);
    parts.add(postalCode);
    return parts.join(', ');
  }

  factory CompanyInfo.defaultCompany() {
    return CompanyInfo(
      companyName: 'PT TRISURYA SOLUSINDO UTAMA',
      companyId: 'NPWP: 00.000.000.0-000.000',
      address: 'Jl. Raya Citarik, Jatireja, Kec. Cikarang Timur',
      city: 'Bekasi',
      province: 'Jawa Barat',
      postalCode: '17530',
      phone: '+6282123602409',
      fax: '+62 21-1234567',
      email: 'info@trisuryasolusindo.com',
      website: 'https://www.trisuryasolusindo.com/',
      department: 'Weighing & Quality Control',
      createdAt: DateTime.now(),
    );
  }
}