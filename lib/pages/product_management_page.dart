import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/database_helper.dart';

class ProductManagementPage extends StatefulWidget {
  final Function(ProductModel)? onProductSelected;
  
  const ProductManagementPage({Key? key, this.onProductSelected}) : super(key: key);

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final dbHelper = DatabaseHelper.instance;
  List<ProductModel> productList = [];
  List<ProductModel> filteredList = [];
  final searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    
    try {
      final data = await dbHelper.readAllProducts();
      setState(() {
        productList = data;
        filteredList = data;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading products: $e');
      setState(() => isLoading = false);
    }
  }

  void _searchProducts(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        filteredList = productList;
      } else {
        filteredList = productList.where((product) {
          return product.productName.toLowerCase().contains(keyword.toLowerCase()) ||
                 product.productCode.toLowerCase().contains(keyword.toLowerCase()) ||
                 product.number.toLowerCase().contains(keyword.toLowerCase());
        }).toList();
      }
    });
  }

  void _showAddProductDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormPage(
          onSaved: () {
            _loadProducts();
          },
        ),
      ),
    );
  }

  void _showEditProductDialog(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormPage(
          product: product,
          onSaved: () {
            _loadProducts();
          },
        ),
      ),
    );
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Delete "${product.productName}"?'),
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

    if (confirm == true && product.id != null) {
      try {
        await dbHelper.deleteProduct(product.id!);
        _loadProducts();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Product deleted'),
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
        title: const Text('Product Management'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: _showAddProductDialog,
            tooltip: 'Add New Product',
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
              onChanged: _searchProducts,
              decoration: InputDecoration(
                hintText: 'Search by name, code, or number...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _searchProducts('');
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

          // Product List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, 
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              productList.isEmpty 
                                  ? 'No products yet' 
                                  : 'No results found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (productList.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _showAddProductDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add First Product'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final product = filteredList[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                if (widget.onProductSelected != null) {
                                  widget.onProductSelected!(product);
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '✓ Selected: ${product.productName}\n'
                                        '💡 Click Product button again to apply to field',
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
                                        // Product Icon & Number
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.purple[50],
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.inventory_2,
                                                color: Colors.purple[700],
                                                size: 24,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                product.number,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.purple[900],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        
                                        // Product Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.productName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple[100],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  product.productCode,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.purple[900],
                                                    fontWeight: FontWeight.w600,
                                                  ),
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
                                                  if (widget.onProductSelected != null) {
                                                    widget.onProductSelected!(product);
                                                    
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '✓ Selected: ${product.productName}\n'
                                                          '💡 Click Product button again to apply',
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
                                                  _showEditProductDialog(product);
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
                                                  _deleteProduct(product);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    
                                    const Divider(height: 20),
                                    
                                    // Product Details
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoChip(
                                            'Unit Weight',
                                            '${product.unitWeight} kg',
                                            Icons.scale,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildInfoChip(
                                            'Target',
                                            '${product.targetValue} kg',
                                            Icons.flag,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoChip(
                                            'Low Limit',
                                            '${product.lowLimit} kg',
                                            Icons.arrow_downward,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildInfoChip(
                                            'Hi Limit',
                                            '${product.hiLimit} kg',
                                            Icons.arrow_upward,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (product.isReadyForCountingMode) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.green[600]!, Colors.green[400]!],
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle, size: 16, color: Colors.white),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                product.countingModeInfo,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    
                                    if (product.description.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.note, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                product.description,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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

  Widget _buildInfoChip(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? Colors.blue).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color ?? Colors.blue[700]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.blue[900],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PRODUCT FORM PAGE
// ==========================================

class ProductFormPage extends StatefulWidget {
  final ProductModel? product;
  final Function? onSaved;

  const ProductFormPage({
    Key? key,
    this.product,
    this.onSaved,
  }) : super(key: key);

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  
  // ✅ Controllers - Material Code REMOVED, Product Code is MANUAL INPUT
  final _numberController = TextEditingController();
  final _productCodeController = TextEditingController();  // ✅ Manual input
  final _productNameController = TextEditingController();
  final _unitWeightController = TextEditingController();
  final _preTareController = TextEditingController();
  final _hiLimitController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _lowLimitController = TextEditingController();
  final _minimumLimitController = TextEditingController();
  final _loosesController = TextEditingController();
  final _labelFormatController = TextEditingController();
  final _labelTotalController = TextEditingController(text: '1');
  final _traceGroupsController = TextEditingController();
  final _groupSelectedController = TextEditingController();
  final _inputSetController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Date fields
  String killDateType = 'Today';
  DateTime? killDateValue;
  String packingDateType = 'Today';
  DateTime? packingDateValue;
  String useByDateType = 'Today';
  DateTime? useByDateValue;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _loadProductData(widget.product!);
    }
  }

  void _loadProductData(ProductModel product) {
    _numberController.text = product.number;
    _productCodeController.text = product.productCode;  // ✅ Load existing code
    _productNameController.text = product.productName;
    _unitWeightController.text = product.unitWeight.toString();
    _preTareController.text = product.preTare.toString();
    _hiLimitController.text = product.hiLimit.toString();
    _targetValueController.text = product.targetValue.toString();
    _lowLimitController.text = product.lowLimit.toString();
    _minimumLimitController.text = product.minimumLimit.toString();
    _loosesController.text = product.looses.toString();
    _labelFormatController.text = product.labelFormat;
    _labelTotalController.text = product.labelTotal.toString();
    _traceGroupsController.text = product.traceGroups;
    _groupSelectedController.text = product.groupSelected;
    _inputSetController.text = product.inputSet;
    _descriptionController.text = product.description;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = ProductModel(
      id: widget.product?.id,
      number: _numberController.text,
      productCode: _productCodeController.text,  // ✅ Use manual input
      productName: _productNameController.text,
      materialCode: '',  // ✅ Always empty
      unitWeight: double.tryParse(_unitWeightController.text) ?? 0.0,
      preTare: double.tryParse(_preTareController.text) ?? 0.0,
      hiLimit: double.tryParse(_hiLimitController.text) ?? 0.0,
      targetValue: double.tryParse(_targetValueController.text) ?? 0.0,
      lowLimit: double.tryParse(_lowLimitController.text) ?? 0.0,
      minimumLimit: double.tryParse(_minimumLimitController.text) ?? 0.0,
      looses: double.tryParse(_loosesController.text) ?? 0.0,
      killDate: _formatDate(killDateType, killDateValue),
      packingDate: _formatDate(packingDateType, packingDateValue),
      useByDate: _formatDate(useByDateType, useByDateValue),
      labelFormat: _labelFormatController.text,
      labelTotal: int.tryParse(_labelTotalController.text) ?? 1,
      traceGroups: _traceGroupsController.text,
      groupSelected: _groupSelectedController.text,
      inputSet: _inputSetController.text,
      description: _descriptionController.text,
      createdAt: widget.product?.createdAt ?? DateTime.now().toIso8601String(),
    );

    try {
      if (widget.product == null) {
        await dbHelper.createProduct(product);
      } else {
        await dbHelper.updateProduct(product);
      }

      if (widget.onSaved != null) widget.onSaved!();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Product saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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

  String _formatDate(String type, DateTime? value) {
    if (type == 'Today') {
      return DateTime.now().toIso8601String();
    } else if (type == 'Calendar' && value != null) {
      return value.toIso8601String();
    }
    return DateTime.now().toIso8601String();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTextField(_numberController, 'Number *', Icons.tag, 'e.g., P001'),
            const SizedBox(height: 16),
            _buildTextField(_productCodeController, 'Product Code *', Icons.qr_code, 'e.g., PROD-001'),
            const SizedBox(height: 16),
            _buildTextField(_productNameController, 'Product Name *', Icons.inventory_2, 'e.g., Premium Rice'),
            const SizedBox(height: 16),
            
            _buildTextField(_unitWeightController, 'Unit Weight (kg)', Icons.scale, 'e.g., 1.5', isNumber: true),
            const SizedBox(height: 16),
            _buildTextField(_preTareController, 'Pre-Tare (kg)', Icons.remove_circle, 'e.g., 0.1', isNumber: true),
            const SizedBox(height: 16),
            _buildTextField(_hiLimitController, 'Hi Limit (kg)', Icons.arrow_upward, 'e.g., 2.0', isNumber: true),
            const SizedBox(height: 16),
            _buildTextField(_targetValueController, 'Target Value (kg)', Icons.flag, 'e.g., 1.5', isNumber: true),
            const SizedBox(height: 16),
            _buildTextField(_lowLimitController, 'Low Limit (kg)', Icons.arrow_downward, 'e.g., 1.0', isNumber: true),
            const SizedBox(height: 16),
            _buildTextField(_minimumLimitController, 'Minimum Limit (kg)', Icons.warning, 'e.g., 0.5', isNumber: true),
            const SizedBox(height: 16),
            _buildTextField(_loosesController, 'Looses (%)', Icons.trending_down, 'e.g., 2', isNumber: true),
            const SizedBox(height: 16),
            
            _buildDateField(
              label: 'Kill Date',
              type: killDateType,
              value: killDateValue,
              options: ['Today', 'Calendar'],
              onTypeChanged: (v) => setState(() => killDateType = v!),
              onDatePicked: (d) => setState(() => killDateValue = d),
            ),
            
            _buildDateField(
              label: 'Packing Date',
              type: packingDateType,
              value: packingDateValue,
              options: ['Today', 'Calendar', 'Kill Date'],
              onTypeChanged: (v) => setState(() => packingDateType = v!),
              onDatePicked: (d) => setState(() => packingDateValue = d),
            ),
            
            _buildDateField(
              label: 'Use By Date',
              type: useByDateType,
              value: useByDateValue,
              options: ['Today', 'Calendar', 'Kill Date', 'Packing Date'],
              onTypeChanged: (v) => setState(() => useByDateType = v!),
              onDatePicked: (d) => setState(() => useByDateValue = d),
            ),
            
            _buildTextField(_labelFormatController, 'Label Format', Icons.label, 'e.g., A4', required: false),
            const SizedBox(height: 16),
            _buildTextField(_labelTotalController, 'Label Total', Icons.format_list_numbered, 'e.g., 1', isNumber: true),
            const SizedBox(height: 16),
            _buildTextField(_traceGroupsController, 'Trace Groups', Icons.group, 'e.g., Group A', required: false),
            const SizedBox(height: 16),
            _buildTextField(_groupSelectedController, 'Group Selected', Icons.check_box, 'e.g., Active', required: false),
            const SizedBox(height: 16),
            _buildTextField(_inputSetController, 'Input Set', Icons.input, 'e.g., Set 1', required: false),
            const SizedBox(height: 16),
            _buildTextField(_descriptionController, 'Description', Icons.description, 'Additional notes', maxLines: 3, required: false),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: _saveProduct,
              icon: const Icon(Icons.save),
              label: Text(widget.product == null ? 'Save Product' : 'Update Product'),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: required
          ? (v) => v?.isEmpty ?? true ? '$label is required' : null
          : null,
    );
  }

  Widget _buildDateField({
    required String label,
    required String type,
    required DateTime? value,
    required List<String> options,
    required Function(String?) onTypeChanged,
    required Function(DateTime) onDatePicked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: type,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: options.map((opt) {
                  return DropdownMenuItem(value: opt, child: Text(opt));
                }).toList(),
                onChanged: onTypeChanged,
              ),
            ),
            const SizedBox(width: 8),
            if (type == 'Calendar')
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: value ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) onDatePicked(picked);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    value != null
                        ? '${value.day}/${value.month}/${value.year}'
                        : 'Pick Date',
                  ),
                ),
              ),
            if (type != 'Calendar')
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(type, style: const TextStyle(color: Colors.grey)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _productCodeController.dispose();  // ✅ Manual input controller
    _productNameController.dispose();
    _unitWeightController.dispose();
    _preTareController.dispose();
    _hiLimitController.dispose();
    _targetValueController.dispose();
    _lowLimitController.dispose();
    _minimumLimitController.dispose();
    _loosesController.dispose();
    _labelFormatController.dispose();
    _labelTotalController.dispose();
    _traceGroupsController.dispose();
    _groupSelectedController.dispose();
    _inputSetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}