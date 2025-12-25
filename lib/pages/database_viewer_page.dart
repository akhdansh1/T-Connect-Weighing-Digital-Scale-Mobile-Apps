import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class DatabaseViewerPage extends StatefulWidget {
  const DatabaseViewerPage({Key? key}) : super(key: key);

  @override
  State<DatabaseViewerPage> createState() => _DatabaseViewerPageState();
}

class _DatabaseViewerPageState extends State<DatabaseViewerPage> {
  final dbHelper = DatabaseHelper.instance;
  
  List<Map<String, dynamic>> barangList = [];
  List<Map<String, dynamic>> resiList = [];
  List<Map<String, dynamic>> pengukuranList = [];
  
  bool isLoading = true;
  String selectedTable = 'barang';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
  setState(() {
    isLoading = true;
  });
  
  // Ambil data
  final barang = await dbHelper.readAllBarang();
  final resi = await dbHelper.readAllResi();
  final pengukuran = await dbHelper.readAllPengukuran();
  
  // Debug - cek apakah data ada
  print('Barang: ${barang.length}');
  print('Resi: ${resi.length}');
  print('Pengukuran: ${pengukuran.length}');
  
  // Update state dengan data baru
  setState(() {
    barangList = barang;
    resiList = resi;
    pengukuranList = pengukuran;
    isLoading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Viewer'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Selector
          Container(
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('barang', 'Barang', barangList.length),
                ),
                Expanded(
                  child: _buildTabButton('resi', 'Resi', resiList.length),
                ),
                Expanded(
                  child: _buildTabButton('pengukuran', 'Pengukuran', pengukuranList.length),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String table, String label, int count) {
    bool isSelected = selectedTable == table;
    return InkWell(
      onTap: () {
        setState(() {
          selectedTable = table;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.blue : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (selectedTable == 'barang') {
      return _buildBarangList();
    } else if (selectedTable == 'resi') {
      return _buildResiList();
    } else {
      return _buildPengukuranList();
    }
  }

  Widget _buildBarangList() {
    if (barangList.isEmpty) {
      return const Center(child: Text('Tidak ada data barang'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: barangList.length,
      itemBuilder: (context, index) {
        var item = barangList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text('${item['id']}'),
            ),
            title: Text(
              item['nama'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Kategori: ${item['kategori']}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDataRow('ID', '${item['id']}'),
                    _buildDataRow('Nama', item['nama']),
                    _buildDataRow('Kategori', item['kategori']),
                    _buildDataRow('Harga', 'Rp ${item['harga']}'),
                    _buildDataRow('Created At', item['created_at']),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResiList() {
    if (resiList.isEmpty) {
      return const Center(child: Text('Tidak ada data resi'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: resiList.length,
      itemBuilder: (context, index) {
        var item = resiList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange[100],
              child: Text('${item['id']}'),
            ),
            title: Text(
              item['nomor'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${item['barang']} - ${item['berat']} ${item['unit']}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDataRow('ID', '${item['id']}'),
                    _buildDataRow('Nomor', item['nomor']),
                    _buildDataRow('Tanggal', item['tanggal']),
                    _buildDataRow('Barang', item['barang']),
                    _buildDataRow('Kategori', item['kategori']),
                    _buildDataRow('Berat', '${item['berat']} ${item['unit']}'),
                    _buildDataRow('Berat (kg)', '${item['berat_kg']} kg'),
                    _buildDataRow('Harga/kg', 'Rp ${item['harga_per_kg']}'),
                    _buildDataRow('Total Harga', 'Rp ${item['total_harga']}'),
                    _buildDataRow('Created At', item['created_at']),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPengukuranList() {
    if (pengukuranList.isEmpty) {
      return const Center(child: Text('Tidak ada data pengukuran'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pengukuranList.length,
      itemBuilder: (context, index) {
        var item = pengukuranList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[100],
              child: Text('${item['id']}'),
            ),
            title: Text(
              item['barang'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${item['berat']} ${item['unit']}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDataRow('ID', '${item['id']}'),
                    _buildDataRow('Tanggal', item['tanggal']),
                    _buildDataRow('Barang', item['barang']),
                    _buildDataRow('Kategori', item['kategori']),
                    _buildDataRow('Berat', '${item['berat']} ${item['unit']}'),
                    _buildDataRow('Berat (kg)', '${item['berat_kg']} kg'),
                    _buildDataRow('Harga Total', 'Rp ${item['harga_total']}'),
                    _buildDataRow('Created At', item['created_at']),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}