class ClientModel {
  final int? id;
  final String serialNumber;
  final String companyCode;
  final String companyName;
  final String companyAddress;
  final String companyTelephone;
  final String contacts;
  final String remarks;
  final String createdAt;
  final String? updatedAt;

  ClientModel({
    this.id,
    required this.serialNumber,
    required this.companyCode,
    required this.companyName,
    required this.companyAddress,
    required this.companyTelephone,
    required this.contacts,
    required this.remarks,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serial_number': serialNumber,
      'company_code': companyCode,
      'company_name': companyName,
      'company_address': companyAddress,
      'company_telephone': companyTelephone,
      'contacts': contacts,
      'remarks': remarks,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'],
      serialNumber: map['serial_number'] ?? '',
      companyCode: map['company_code'] ?? '',
      companyName: map['company_name'] ?? '',
      companyAddress: map['company_address'] ?? '',
      companyTelephone: map['company_telephone'] ?? '',
      contacts: map['contacts'] ?? '',
      remarks: map['remarks'] ?? '',
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at'],
    );
  }

  String get displayName => '$companyCode - $companyName';
}