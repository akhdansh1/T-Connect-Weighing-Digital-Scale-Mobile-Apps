class Operator {
  final int? id;
  final String operatorCode;
  final String operatorName;
  final String username;
  final String? password;
  final String role;
  final String? employeeId;
  final String? department;
  final String? phone;
  final String? email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;

  Operator({
    this.id,
    required this.operatorCode,
    required this.operatorName,
    required this.username,
    this.password,
    this.role = 'Operator',
    this.employeeId,
    this.department,
    this.phone,
    this.email,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operator_code': operatorCode,
      'operator_name': operatorName,
      'username': username,
      'password': password,
      'role': role,
      'employee_id': employeeId,
      'department': department,
      'phone': phone,
      'email': email,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  factory Operator.fromMap(Map<String, dynamic> map) {
    return Operator(
      id: map['id'],
      operatorCode: map['operator_code'] ?? '',
      operatorName: map['operator_name'] ?? '',
      username: map['username'] ?? '',
      password: map['password'],
      role: map['role'] ?? 'Operator',
      employeeId: map['employee_id'],
      department: map['department'],
      phone: map['phone'],
      email: map['email'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      lastLogin: map['last_login'] != null ? DateTime.parse(map['last_login']) : null,
    );
  }

  Operator copyWith({
    int? id, String? operatorCode, String? operatorName, String? username,
    String? password, String? role, String? employeeId, String? department,
    String? phone, String? email, bool? isActive,
    DateTime? createdAt, DateTime? updatedAt, DateTime? lastLogin,
  }) {
    return Operator(
      id: id ?? this.id,
      operatorCode: operatorCode ?? this.operatorCode,
      operatorName: operatorName ?? this.operatorName,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  String getDisplayName() => '$operatorCode - $operatorName';
  String getFullInfo() {
    List<String> parts = [operatorName, '($role)'];
    if (department != null && department!.isNotEmpty) parts.add(department!);
    return parts.join(' - ');
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isSupervisor => role.toLowerCase() == 'supervisor' || role.toLowerCase() == 'admin';
  bool get isQCInspector => role.toLowerCase().contains('qc') || role.toLowerCase().contains('inspector');

  static const List<String> roles = [
    'Admin', 'Supervisor', 'Operator', 'QC Inspector', 'Warehouse Staff',
  ];

  factory Operator.defaultOperator() {
    return Operator(
      operatorCode: 'OP-001',
      operatorName: 'System Administrator',
      username: 'admin',
      role: 'Admin',
      department: 'IT',
      createdAt: DateTime.now(),
    );
  }
}