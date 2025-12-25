import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import '../models/material.dart' as mat;

class MaterialManagementPage extends StatefulWidget {
  const MaterialManagementPage({Key? key}) : super(key: key);

  @override
  State<MaterialManagementPage> createState() => _MaterialManagementPageState();
}

class _MaterialManagementPageState extends State<MaterialManagementPage> {
  final dbHelper = DatabaseHelper.instance;
  List<mat.Material> materials = [];
  List<mat.Material> filteredMaterials = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() => isLoading = true);
    
    try {
      final allMaterials = await dbHelper.readAllMaterials();
      setState(() {
        materials = allMaterials;
        _filterMaterials();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading materials: $e');
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading materials: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterMaterials() {
    setState(() {
      filteredMaterials = materials.where((material) {
        final matchesSearch = searchQuery.isEmpty ||
            material.materialName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            material.materialCode.toLowerCase().contains(searchQuery.toLowerCase());
        
        final matchesCategory = selectedCategory == 'All' ||
            material.category == selectedCategory;
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _showAddEditDialog({mat.Material? material}) {
    final isEdit = material != null;
    
    final codeController = TextEditingController(
      text: material?.materialCode ?? _generateMaterialCode(),
    );
    final nameController = TextEditingController(text: material?.materialName ?? '');
    final priceController = TextEditingController(
      text: material?.pricePerKg.toString() ?? '0',
    );
    final standardWeightController = TextEditingController(
      text: material?.standardWeight?.toString() ?? '',
    );
    final toleranceController = TextEditingController(
      text: material?.tolerance?.toString() ?? '0.5',
    );
    final descriptionController = TextEditingController(text: material?.description ?? '');
    
    String selectedCategory = material?.category ?? mat.Material.categories[0];
    String selectedGrade = material?.grade ?? mat.Material.grades[4]; // 'Standard'
    String selectedUnit = material?.unit ?? 'KG';
    bool isActive = material?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit : Icons.add_circle,
                color: Colors.blue[700],
              ),
              const SizedBox(width: 8),
              Text(isEdit ? 'Edit Material' : 'Add New Material'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Material Code
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: 'Material Code *',
                      hintText: 'MAT-XXXXXX',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.qr_code),
                      enabled: !isEdit, // Tidak bisa edit kode
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Material Name
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Material Name *',
                      hintText: 'e.g., Beras Premium',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  
                  // Category & Grade
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: mat.Material.categories
                              .map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCategory = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedGrade,
                          decoration: const InputDecoration(
                            labelText: 'Grade *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.star),
                          ),
                          items: mat.Material.grades
                              .map((grade) => DropdownMenuItem(
                                    value: grade,
                                    child: Text(grade),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedGrade = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Unit
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    items: mat.Material.units
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedUnit = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Price per KG
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price per Unit',
                      hintText: '0',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),
                  
                  // Standard Weight (Optional)
                  TextField(
                    controller: standardWeightController,
                    decoration: InputDecoration(
                      labelText: 'Standard Weight (Optional)',
                      hintText: 'e.g., 25.0',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.fitness_center),
                      suffixText: selectedUnit,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  
                  // Tolerance (%)
                  TextField(
                    controller: toleranceController,
                    decoration: const InputDecoration(
                      labelText: 'Tolerance (%)',
                      hintText: '0.5',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tune),
                      suffixText: '%',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  
                  // Description
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Additional notes...',
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
                      isActive ? 'Material is active' : 'Material is inactive',
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter material name'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                // Create/Update Material
                final newMaterial = mat.Material(
                  id: material?.id,
                  materialCode: codeController.text.trim(),
                  materialName: nameController.text.trim(),
                  category: selectedCategory,
                  grade: selectedGrade,
                  unit: selectedUnit,
                  pricePerKg: int.tryParse(priceController.text) ?? 0,
                  standardWeight: standardWeightController.text.trim().isNotEmpty
                      ? double.tryParse(standardWeightController.text)
                      : null,
                  tolerance: double.tryParse(toleranceController.text) ?? 0.5,
                  description: descriptionController.text.trim().isNotEmpty
                      ? descriptionController.text.trim()
                      : null,
                  isActive: isActive,
                  createdAt: material?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                
                try {
                  if (isEdit) {
                    await dbHelper.updateMaterial(newMaterial);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Material updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    await dbHelper.createMaterial(newMaterial);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Material added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                  
                  _loadMaterials();
                } catch (e) {
                  print('Error saving material: $e');
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(mat.Material material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Material?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${material.materialName}"?\n\nThis action cannot be undone.',
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
                await dbHelper.deleteMaterial(material.id!);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Material deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                
                _loadMaterials();
              } catch (e) {
                print('Error deleting material: $e');
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

  String _generateMaterialCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'MAT-${timestamp.toString().substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Management'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMaterials,
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
                    hintText: 'Search materials...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    searchQuery = value;
                    _filterMaterials();
                  },
                ),
                const SizedBox(height: 12),
                
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', selectedCategory == 'All'),
                      ...mat.Material.categories.map(
                        (category) => _buildFilterChip(
                          category,
                          selectedCategory == category,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Statistics Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.inventory_2,
                  'Total',
                  materials.length.toString(),
                  Colors.blue,
                ),
                _buildStatItem(
                  Icons.check_circle,
                  'Active',
                  materials.where((m) => m.isActive).length.toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  Icons.filter_list,
                  'Filtered',
                  filteredMaterials.length.toString(),
                  Colors.orange,
                ),
              ],
            ),
          ),
          
          // Materials List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredMaterials.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadMaterials,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredMaterials.length,
                          itemBuilder: (context, index) {
                            final material = filteredMaterials[index];
                            return _buildMaterialCard(material);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add),
        label: const Text('Add Material'),
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
            selectedCategory = selected ? label : 'All';
            _filterMaterials();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue[700],
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
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? 'No materials yet'
                : 'No materials found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Tap the + button to add your first material'
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

  Widget _buildMaterialCard(mat.Material material) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showAddEditDialog(material: material),
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
                      color: material.isActive
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: material.isActive ? Colors.blue : Colors.grey,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.materialName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          material.materialCode,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!material.isActive)
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.category,
                    material.category,
                    Colors.purple,
                  ),
                  _buildInfoChip(
                    Icons.star,
                    material.grade,
                    Colors.orange,
                  ),
                  _buildInfoChip(
                    Icons.straighten,
                    material.unit,
                    Colors.teal,
                  ),
                  if (material.hasPrice)
                    _buildInfoChip(
                      Icons.attach_money,
                      'Rp ${_formatNumber(material.pricePerKg)}',
                      Colors.green,
                    ),
                ],
              ),
              if (material.description != null && material.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    material.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showAddEditDialog(material: material),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(material),
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

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}