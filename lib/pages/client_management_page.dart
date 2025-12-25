import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../services/database_helper.dart';

class ClientManagementPage extends StatefulWidget {
  final Function(ClientModel)? onClientSelected;
  
  const ClientManagementPage({
    Key? key,
    this.onClientSelected,
  }) : super(key: key);

  @override
  State<ClientManagementPage> createState() => _ClientManagementPageState();
}

class _ClientManagementPageState extends State<ClientManagementPage> {
  final dbHelper = DatabaseHelper.instance;
  List<ClientModel> clientList = [];
  List<ClientModel> filteredList = [];
  final searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => isLoading = true);
    
    try {
      final data = await dbHelper.readAllClients();
      setState(() {
        clientList = data.map((e) => ClientModel.fromMap(e)).toList();
        filteredList = clientList;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading clients: $e');
      setState(() => isLoading = false);
    }
  }

  void _searchClients(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        filteredList = clientList;
      } else {
        filteredList = clientList.where((client) {
          return client.companyName.toLowerCase().contains(keyword.toLowerCase()) ||
                 client.companyCode.toLowerCase().contains(keyword.toLowerCase()) ||
                 client.serialNumber.toLowerCase().contains(keyword.toLowerCase());
        }).toList();
      }
    });
  }

  void _showAddClientDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientFormPage(
          onSave: () {
            _loadClients();
          },
        ),
      ),
    );
  }

  void _showEditClientDialog(ClientModel client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientFormPage(
          client: client,
          onSave: () {
            _loadClients();
          },
        ),
      ),
    );
  }

  Future<void> _deleteClient(ClientModel client) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client?'),
        content: Text('Delete "${client.companyName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && client.id != null) {
      try {
        await dbHelper.deleteClient(client.id!);
        _loadClients();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Client deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Management'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: _showAddClientDialog,
            tooltip: 'Add New Client',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: TextField(
              controller: searchController,
              onChanged: _searchClients,
              decoration: InputDecoration(
                hintText: 'Search by name, code, or serial...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _searchClients('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Client List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business_outlined, 
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              clientList.isEmpty 
                                  ? 'No clients yet' 
                                  : 'No results found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (clientList.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _showAddClientDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add First Client'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final client = filteredList[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                // ✅ TETAP DI HALAMAN INI - TIDAK LANGSUNG POP
                                if (widget.onClientSelected != null) {
                                  widget.onClientSelected!(client);
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '✓ Selected: ${client.companyName}\n'
                                        '💡 Click Client button again to apply to field',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 3),
                                      action: SnackBarAction(
                                        label: 'Back',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Company Icon
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.business,
                                            color: Colors.blue[700],
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        
                                        // Company Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                client.companyName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Code: ${client.companyCode}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Actions Menu
                                        PopupMenuButton(
                                          icon: const Icon(Icons.more_vert),
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.check_circle, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Select'),
                                                ],
                                              ),
                                              onTap: () {
                                                Future.delayed(Duration.zero, () {
                                                  if (widget.onClientSelected != null) {
                                                    widget.onClientSelected!(client);
                                                    
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '✓ Selected: ${client.companyName}\n'
                                                          '💡 Click Client button again to apply',
                                                        ),
                                                        backgroundColor: Colors.green,
                                                        duration: const Duration(seconds: 3),
                                                        action: SnackBarAction(
                                                          label: 'Back',
                                                          textColor: Colors.white,
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                });
                                              },
                                            ),
                                            PopupMenuItem(
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.edit, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                              onTap: () {
                                                Future.delayed(Duration.zero, () {
                                                  _showEditClientDialog(client);
                                                });
                                              },
                                            ),
                                            PopupMenuItem(
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                                ],
                                              ),
                                              onTap: () {
                                                Future.delayed(Duration.zero, () {
                                                  _deleteClient(client);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    
                                    const Divider(height: 20),
                                    
                                    // Details
                                    _buildInfoRow(Icons.location_on, client.companyAddress),
                                    const SizedBox(height: 6),
                                    _buildInfoRow(Icons.phone, client.companyTelephone),
                                    const SizedBox(height: 6),
                                    _buildInfoRow(Icons.person, client.contacts),
                                    
                                    if (client.remarks.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      _buildInfoRow(Icons.note, client.remarks),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}

class ClientFormPage extends StatefulWidget {
  final ClientModel? client;
  final VoidCallback onSave;

  const ClientFormPage({
    Key? key,
    this.client,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends State<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  
  late TextEditingController serialController;
  late TextEditingController codeController;
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController phoneController;
  late TextEditingController contactsController;
  late TextEditingController remarksController;

  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    isEditing = widget.client != null;
    
    serialController = TextEditingController(text: widget.client?.serialNumber ?? '');
    codeController = TextEditingController(text: widget.client?.companyCode ?? '');
    nameController = TextEditingController(text: widget.client?.companyName ?? '');
    addressController = TextEditingController(text: widget.client?.companyAddress ?? '');
    phoneController = TextEditingController(text: widget.client?.companyTelephone ?? '');
    contactsController = TextEditingController(text: widget.client?.contacts ?? '');
    remarksController = TextEditingController(text: widget.client?.remarks ?? '');
  }

  @override
  void dispose() {
    serialController.dispose();
    codeController.dispose();
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    contactsController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final clientData = {
        'serial_number': serialController.text.trim(),
        'company_code': codeController.text.trim(),
        'company_name': nameController.text.trim(),
        'company_address': addressController.text.trim(),
        'company_telephone': phoneController.text.trim(),
        'contacts': contactsController.text.trim(),
        'remarks': remarksController.text.trim(),
      };

      if (isEditing && widget.client?.id != null) {
        await dbHelper.updateClient(widget.client!.id!, clientData);
      } else {
        await dbHelper.createClient(clientData);
      }

      widget.onSave();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? '✓ Client updated' : '✓ Client created'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Client' : 'Add New Client'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTextField(
              controller: serialController,
              label: 'Serial Number *',
              icon: Icons.tag,
              hint: 'e.g., SN-001',
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: codeController,
              label: 'Company Code *',
              icon: Icons.business_center,
              hint: 'e.g., COMP-001',
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: nameController,
              label: 'Company Name *',
              icon: Icons.business,
              hint: 'e.g., PT Maju Jaya',
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: addressController,
              label: 'Company Address *',
              icon: Icons.location_on,
              hint: 'Full address',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: phoneController,
              label: 'Company Telephone *',
              icon: Icons.phone,
              hint: 'e.g., 021-1234567',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: contactsController,
              label: 'Contact Person *',
              icon: Icons.person,
              hint: 'Name, position, phone',
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: remarksController,
              label: 'Remarks',
              icon: Icons.note,
              hint: 'Additional notes (optional)',
              maxLines: 3,
              required: false,
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: _saveClient,
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'Update Client' : 'Save Client'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    bool required = true,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
    );
  }
}