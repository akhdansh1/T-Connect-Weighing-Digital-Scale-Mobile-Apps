import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/operator.dart';

class OperatorManagementPage extends StatefulWidget {
  const OperatorManagementPage({Key? key}) : super(key: key);

  @override
  State<OperatorManagementPage> createState() => _OperatorManagementPageState();
}

class _OperatorManagementPageState extends State<OperatorManagementPage> {
  final dbHelper = DatabaseHelper.instance;
  List<Operator> operators = [];
  List<Operator> filteredOperators = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedRole = 'All';

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  Future<void> _loadOperators() async {
    setState(() => isLoading = true);
    
    try {
      final allOperators = await dbHelper.readAllOperators();
      setState(() {
        operators = allOperators;
        _filterOperators();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading operators: $e');
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading operators: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterOperators() {
    setState(() {
      filteredOperators = operators.where((operator) {
        final matchesSearch = searchQuery.isEmpty ||
            operator.operatorName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            operator.operatorCode.toLowerCase().contains(searchQuery.toLowerCase()) ||
            operator.username.toLowerCase().contains(searchQuery.toLowerCase());
        
        final matchesRole = selectedRole == 'All' ||
            operator.role == selectedRole;
        
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  void _showAddEditDialog({Operator? operator}) {
    final isEdit = operator != null;
    
    final codeController = TextEditingController(
      text: operator?.operatorCode ?? _generateOperatorCode(),
    );
    final nameController = TextEditingController(text: operator?.operatorName ?? '');
    final usernameController = TextEditingController(text: operator?.username ?? '');
    final passwordController = TextEditingController(text: operator?.password ?? '');
    final employeeIdController = TextEditingController(text: operator?.employeeId ?? '');
    final departmentController = TextEditingController(text: operator?.department ?? '');
    final phoneController = TextEditingController(text: operator?.phone ?? '');
    final emailController = TextEditingController(text: operator?.email ?? '');
    
    String selectedRole = operator?.role ?? 'Operator';
    bool isActive = operator?.isActive ?? true;
    bool showPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit : Icons.add_circle,
                color: Colors.purple[700],
              ),
              const SizedBox(width: 8),
              Text(isEdit ? 'Edit Operator' : 'Add New Operator'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Operator Code
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: 'Operator Code *',
                      hintText: 'OP-XXXXXX',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.qr_code),
                      enabled: !isEdit,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Operator Name
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'e.g., John Doe',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  
                  // Username & Password
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_circle),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: !showPassword,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Role & Employee ID
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.work),
                          ),
                          items: ['Operator', 'Supervisor', 'Manager', 'Admin']
                              .map((role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedRole = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: employeeIdController,
                          decoration: const InputDecoration(
                            labelText: 'Employee ID',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Department
                  TextField(
                    controller: departmentController,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      hintText: 'e.g., Production',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business_center),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  
                  // Phone & Email
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Active Status
                  SwitchListTile(
                    title: const Text('Active Status'),
                    subtitle: Text(
                      isActive ? 'Operator is active' : 'Operator is inactive',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value;
                      });
                    },
                    secondary: Icon(
                      isActive ? Icons.check_circle : Icons.cancel,
                      color: isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // Validation
                if (nameController.text.trim().isEmpty ||
                    usernameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill name and username'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                // Create/Update Operator
                final newOperator = Operator(
                  id: operator?.id,
                  operatorCode: codeController.text.trim(),
                  operatorName: nameController.text.trim(),
                  username: usernameController.text.trim(),
                  password: passwordController.text.trim().isNotEmpty
                      ? passwordController.text.trim()
                      : null,
                  role: selectedRole,
                  employeeId: employeeIdController.text.trim().isNotEmpty
                      ? employeeIdController.text.trim()
                      : null,
                  department: departmentController.text.trim().isNotEmpty
                      ? departmentController.text.trim()
                      : null,
                  phone: phoneController.text.trim().isNotEmpty
                      ? phoneController.text.trim()
                      : null,
                  email: emailController.text.trim().isNotEmpty
                      ? emailController.text.trim()
                      : null,
                  isActive: isActive,
                  createdAt: operator?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                
                try {
                  if (isEdit) {
                    await dbHelper.updateOperator(newOperator);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Operator updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    await dbHelper.createOperator(newOperator);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Operator added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                  
                  _loadOperators();
                } catch (e) {
                  print('Error saving operator: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: Icon(isEdit ? Icons.save : Icons.add),
              label: Text(isEdit ? 'Update' : 'Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Operator operator) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Operator?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${operator.operatorName}"?\n\nThis will set the operator as inactive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // Soft delete - set as inactive
                final inactiveOperator = operator.copyWith(
                  isActive: false,
                  updatedAt: DateTime.now(),
                );
                await dbHelper.updateOperator(inactiveOperator);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Operator deactivated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                
                _loadOperators();
              } catch (e) {
                print('Error deleting operator: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _generateOperatorCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'OP-${timestamp.toString().substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator Management'),
        backgroundColor: Colors.purple[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOperators,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search operators...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    searchQuery = value;
                    _filterOperators();
                  },
                ),
                const SizedBox(height: 12),
                
                // Role Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', selectedRole == 'All'),
                      _buildFilterChip('Operator', selectedRole == 'Operator'),
                      _buildFilterChip('Supervisor', selectedRole == 'Supervisor'),
                      _buildFilterChip('Manager', selectedRole == 'Manager'),
                      _buildFilterChip('Admin', selectedRole == 'Admin'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Statistics Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.purple[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.people,
                  'Total',
                  operators.length.toString(),
                  Colors.purple,
                ),
                _buildStatItem(
                  Icons.check_circle,
                  'Active',
                  operators.where((o) => o.isActive).length.toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  Icons.filter_list,
                  'Filtered',
                  filteredOperators.length.toString(),
                  Colors.orange,
                ),
              ],
            ),
          ),
          
          // Operators List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOperators.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadOperators,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredOperators.length,
                          itemBuilder: (context, index) {
                            final operator = filteredOperators[index];
                            return _buildOperatorCard(operator);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.purple[700],
        icon: const Icon(Icons.add),
        label: const Text('Add Operator'),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedRole = selected ? label : 'All';
            _filterOperators();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.purple[100],
        checkmarkColor: Colors.purple[700],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No operators yet' : 'No operators found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Tap the + button to add your first operator'
                : 'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorCard(Operator operator) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showAddEditDialog(operator: operator),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: operator.isActive
                        ? Colors.purple[100]
                        : Colors.grey[300],
                    child: Text(
                      operator.operatorName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: operator.isActive ? Colors.purple : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          operator.operatorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          operator.operatorCode,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!operator.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.account_circle, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    operator.username,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.work, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    operator.role,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
              if (operator.department != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.business_center, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      operator.department!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
              if (operator.phone != null || operator.email != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (operator.phone != null) ...[
                      Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        operator.phone!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                    if (operator.phone != null && operator.email != null)
                      const SizedBox(width: 16),
                    if (operator.email != null) ...[
                      Icon(Icons.email, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          operator.email!,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showAddEditDialog(operator: operator),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(operator),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}