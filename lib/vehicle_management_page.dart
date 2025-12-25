import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import '../models/vehicle.dart';

class VehicleManagementPage extends StatefulWidget {
  const VehicleManagementPage({Key? key}) : super(key: key);

  @override
  State<VehicleManagementPage> createState() => _VehicleManagementPageState();
}

class _VehicleManagementPageState extends State<VehicleManagementPage> {
  final dbHelper = DatabaseHelper.instance;
  List<Vehicle> vehicles = [];
  List<Vehicle> filteredVehicles = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedType = 'All';

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => isLoading = true);
    
    try {
      final allVehicles = await dbHelper.readAllVehicles();
      setState(() {
        vehicles = allVehicles;
        _filterVehicles();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading vehicles: $e');
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vehicles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterVehicles() {
    setState(() {
      filteredVehicles = vehicles.where((vehicle) {
        final matchesSearch = searchQuery.isEmpty ||
            vehicle.vehicleNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (vehicle.driverName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
        
        final matchesType = selectedType == 'All' ||
            vehicle.vehicleType == selectedType;
        
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  void _showAddEditDialog({Vehicle? vehicle}) {
    final isEdit = vehicle != null;
    
    final numberController = TextEditingController(text: vehicle?.vehicleNumber ?? '');
    final driverNameController = TextEditingController(text: vehicle?.driverName ?? '');
    final driverPhoneController = TextEditingController(text: vehicle?.driverPhone ?? '');
    final driverLicenseController = TextEditingController(text: vehicle?.driverLicense ?? '');
    final tareWeightController = TextEditingController(
      text: vehicle?.tareWeight?.toString() ?? '',
    );
    final companyController = TextEditingController(text: vehicle?.company ?? '');
    final notesController = TextEditingController(text: vehicle?.notes ?? '');
    
    String selectedType = vehicle?.vehicleType ?? 'Truck';
    bool isActive = vehicle?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit : Icons.add_circle,
                color: Colors.orange[700],
              ),
              const SizedBox(width: 8),
              Text(isEdit ? 'Edit Vehicle' : 'Add New Vehicle'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Vehicle Number
                  TextField(
                    controller: numberController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Number *',
                      hintText: 'e.g., B 1234 XYZ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_shipping),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  
                  // Vehicle Type
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Type *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: [
                      'Truck',
                      'Pickup',
                      'Van',
                      'Container',
                      'Dump Truck',
                      'Trailer',
                      'Motorcycle',
                      'Other'
                    ].map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Tare Weight
                  TextField(
                    controller: tareWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Tare Weight (Optional)',
                      hintText: 'Vehicle empty weight in KG',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.fitness_center),
                      suffixText: 'KG',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  
                  // Company
                  TextField(
                    controller: companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company / Owner',
                      hintText: 'e.g., PT Transport ABC',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  
                  // Divider
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'Driver Information',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Driver Name
                  TextField(
                    controller: driverNameController,
                    decoration: const InputDecoration(
                      labelText: 'Driver Name',
                      hintText: 'e.g., John Driver',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  
                  // Driver Phone & License
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: driverPhoneController,
                          decoration: const InputDecoration(
                            labelText: 'Driver Phone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: driverLicenseController,
                          decoration: const InputDecoration(
                            labelText: 'License No.',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.credit_card),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Notes
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Additional information...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  
                  // Active Status
                  SwitchListTile(
                    title: const Text('Active Status'),
                    subtitle: Text(
                      isActive ? 'Vehicle is active' : 'Vehicle is inactive',
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
                if (numberController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter vehicle number'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                // Create/Update Vehicle
                final newVehicle = Vehicle(
                  id: vehicle?.id,
                  vehicleNumber: numberController.text.trim().toUpperCase(),
                  vehicleType: selectedType,
                  driverName: driverNameController.text.trim().isNotEmpty
                      ? driverNameController.text.trim()
                      : null,
                  driverPhone: driverPhoneController.text.trim().isNotEmpty
                      ? driverPhoneController.text.trim()
                      : null,
                  driverLicense: driverLicenseController.text.trim().isNotEmpty
                      ? driverLicenseController.text.trim()
                      : null,
                  tareWeight: tareWeightController.text.trim().isNotEmpty
                      ? double.tryParse(tareWeightController.text)
                      : null,
                  company: companyController.text.trim().isNotEmpty
                      ? companyController.text.trim()
                      : null,
                  isActive: isActive,
                  notes: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                  createdAt: vehicle?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                
                try {
                  if (isEdit) {
                    await dbHelper.updateVehicle(newVehicle);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Vehicle updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    await dbHelper.createVehicle(newVehicle);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Vehicle added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                  
                  _loadVehicles();
                } catch (e) {
                  print('Error saving vehicle: $e');
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
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Vehicle?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${vehicle.vehicleNumber}"?\n\nThis action cannot be undone.',
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
                await dbHelper.deleteVehicle(vehicle.id!);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Vehicle deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                
                _loadVehicles();
              } catch (e) {
                print('Error deleting vehicle: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Management'),
        backgroundColor: Colors.orange[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVehicles,
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
                    hintText: 'Search vehicles...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    searchQuery = value;
                    _filterVehicles();
                  },
                ),
                const SizedBox(height: 12),
                
                // Type Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', selectedType == 'All'),
                      _buildFilterChip('Truck', selectedType == 'Truck'),
                      _buildFilterChip('Pickup', selectedType == 'Pickup'),
                      _buildFilterChip('Van', selectedType == 'Van'),
                      _buildFilterChip('Container', selectedType == 'Container'),
                      _buildFilterChip('Other', selectedType == 'Other'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Statistics Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.orange[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.local_shipping,
                  'Total',
                  vehicles.length.toString(),
                  Colors.orange,
                ),
                _buildStatItem(
                  Icons.check_circle,
                  'Active',
                  vehicles.where((v) => v.isActive).length.toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  Icons.filter_list,
                  'Filtered',
                  filteredVehicles.length.toString(),
                  Colors.blue,
                ),
              ],
            ),
          ),
          
          // Vehicles List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredVehicles.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadVehicles,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredVehicles.length,
                          itemBuilder: (context, index) {
                            final vehicle = filteredVehicles[index];
                            return _buildVehicleCard(vehicle);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.orange[700],
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
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
            selectedType = selected ? label : 'All';
            _filterVehicles();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.orange[100],
        checkmarkColor: Colors.orange[700],
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
            Icons.local_shipping_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No vehicles yet' : 'No vehicles found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Tap the + button to add your first vehicle'
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

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showAddEditDialog(vehicle: vehicle),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: vehicle.isActive
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      color: vehicle.isActive ? Colors.orange : Colors.grey,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.vehicleNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vehicle.vehicleType,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!vehicle.isActive)
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
              
              if (vehicle.company != null) ...[
                Row(
                  children: [
                    Icon(Icons.business, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      vehicle.company!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              
              if (vehicle.driverName != null) ...[
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      vehicle.driverName!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    if (vehicle.driverPhone != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        vehicle.driverPhone!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
              ],
              
              if (vehicle.hasTareWeight) ...[
                Row(
                  children: [
                    Icon(Icons.fitness_center, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Tare Weight: ${vehicle.tareWeight!.toStringAsFixed(0)} KG',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              
              if (vehicle.driverLicense != null) ...[
                Row(
                  children: [
                    Icon(Icons.credit_card, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'License: ${vehicle.driverLicense!}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showAddEditDialog(vehicle: vehicle),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(vehicle),
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