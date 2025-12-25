import 'package:flutter/material.dart';
import '../models/id_model.dart';
import '../services/database_helper.dart';

class IdManagementPage extends StatefulWidget {
  final Function(IdModel)? onIdSelected;
  
  const IdManagementPage({
    Key? key,
    this.onIdSelected,
  }) : super(key: key);

  @override
  State<IdManagementPage> createState() => _IdManagementPageState();
}

class _IdManagementPageState extends State<IdManagementPage> {
  final dbHelper = DatabaseHelper.instance;
  List<IdModel> idList = [];
  List<IdModel> filteredList = [];
  final searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIds();
  }

  Future<void> _loadIds() async {
    setState(() => isLoading = true);
    
    try {
      final data = await dbHelper.readAllIds();
      setState(() {
        idList = data.map((e) => IdModel.fromMap(e)).toList();
        filteredList = idList;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading IDs: $e');
      setState(() => isLoading = false);
    }
  }

  void _searchIds(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        filteredList = idList;
      } else {
        filteredList = idList.where((id) {
          return id.name.toLowerCase().contains(keyword.toLowerCase()) ||
                 id.barcode.toLowerCase().contains(keyword.toLowerCase());
        }).toList();
      }
    });
  }

  void _showAddIdDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IdFormPage(
          onSave: () {
            _loadIds();
          },
        ),
      ),
    );
  }

  void _showEditIdDialog(IdModel id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IdFormPage(
          id: id,
          onSave: () {
            _loadIds();
          },
        ),
      ),
    );
  }

  Future<void> _deleteId(IdModel id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ID?'),
        content: Text('Delete "${id.name}"?'),
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

    if (confirm == true && id.id != null) {
      try {
        await dbHelper.deleteId(id.id!);
        _loadIds();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ ID deleted'),
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
        title: const Text('ID Management'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: _showAddIdDialog,
            tooltip: 'Add New ID',
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
              onChanged: _searchIds,
              decoration: InputDecoration(
                hintText: 'Search by name or barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _searchIds('');
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

          // ID List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.badge_outlined, 
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              idList.isEmpty 
                                  ? 'No IDs yet' 
                                  : 'No results found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (idList.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _showAddIdDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add First ID'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final id = filteredList[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                // ✅ TETAP DI HALAMAN INI - TIDAK LANGSUNG POP
                                if (widget.onIdSelected != null) {
                                  widget.onIdSelected!(id);
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '✓ Selected: ${id.name}\n'
                                        '💡 Click ID button again to apply to field',
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
                                child: Row(
                                  children: [
                                    // ID Icon
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.badge,
                                        color: Colors.blue[700],
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // ID Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            id.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (id.barcode.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.qr_code, 
                                                    size: 14, 
                                                    color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  id.barcode,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600],
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (id.remarks.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              id.remarks,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                                fontStyle: FontStyle.italic,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
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
                                              if (widget.onIdSelected != null) {
                                                widget.onIdSelected!(id);
                                                
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '✓ Selected: ${id.name}\n'
                                                      '💡 Click ID button again to apply',
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
                                              _showEditIdDialog(id);
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
                                              _deleteId(id);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
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
}

class IdFormPage extends StatefulWidget {
  final IdModel? id;
  final VoidCallback onSave;

  const IdFormPage({
    Key? key,
    this.id,
    required this.onSave,
  }) : super(key: key);

  @override
  State<IdFormPage> createState() => _IdFormPageState();
}

class _IdFormPageState extends State<IdFormPage> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  
  late TextEditingController nameController;
  late TextEditingController barcodeController;
  late TextEditingController remarksController;

  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    isEditing = widget.id != null;
    
    nameController = TextEditingController(text: widget.id?.name ?? '');
    barcodeController = TextEditingController(text: widget.id?.barcode ?? '');
    remarksController = TextEditingController(text: widget.id?.remarks ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    barcodeController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  Future<void> _saveId() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final idData = {
        'name': nameController.text.trim(),
        'barcode': barcodeController.text.trim(),
        'remarks': remarksController.text.trim(),
      };

      if (isEditing && widget.id?.id != null) {
        await dbHelper.updateId(widget.id!.id!, idData);
      } else {
        await dbHelper.createId(idData);
      }

      widget.onSave();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? '✓ ID updated' : '✓ ID created'),
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
        title: Text(isEditing ? 'Edit ID' : 'Add New ID'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Name Field
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g., John Doe',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Barcode Field
            TextFormField(
              controller: barcodeController,
              decoration: InputDecoration(
                labelText: 'Barcode *',
                hintText: 'e.g., 123456789',
                prefixIcon: const Icon(Icons.qr_code),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Barcode is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Remarks Field
            TextFormField(
              controller: remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Remarks',
                hintText: 'Additional notes (optional)',
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Save Button
            ElevatedButton.icon(
              onPressed: _saveId,
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'Update ID' : 'Save ID'),
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
}