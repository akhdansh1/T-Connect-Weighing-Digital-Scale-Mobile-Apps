import 'package:flutter/material.dart';

class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isConnected;
  final bool showRawData;
  final VoidCallback onToggleRawData;
  final VoidCallback onDatabaseViewer;
  final VoidCallback onBarangList;
  final VoidCallback onHistory;
  final VoidCallback onReceipts;
  final VoidCallback onDashboard;
  final VoidCallback onLabelDesigner;
  final VoidCallback onSettings;
  final VoidCallback onRequestPrint;
  final VoidCallback onPrintLog;
  final VoidCallback onSendCommand;
  final VoidCallback onChangePrinter;
  final int historyCount;
  final int receiptsCount;
  final bool isPrintEnabled;
  final VoidCallback? onTogglePrint;
  final VoidCallback? onStatisticalSession;  // ✅ NEW PARAMETER
  final String? deviceName;
  final String connectionMode;
  final String? defaultPrinterName;

  const ResponsiveAppBar({
    Key? key,
    required this.title,
    required this.isConnected,
    required this.showRawData,
    required this.onToggleRawData,
    required this.onDatabaseViewer,
    required this.onBarangList,
    required this.onHistory,
    required this.onReceipts,
    required this.onDashboard,
    required this.onLabelDesigner,
    required this.onSettings,
    required this.onRequestPrint,
    required this.onPrintLog,
    required this.onSendCommand,
    required this.onChangePrinter,
    required this.isPrintEnabled,
    this.onTogglePrint,
    this.onStatisticalSession,  // ✅ NEW IN CONSTRUCTOR
    this.historyCount = 0,
    this.receiptsCount = 0,
    this.deviceName,
    this.connectionMode = 'continuous',
    this.defaultPrinterName,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
  
  // ✅ Variable name: maxVisibleIcons
  final maxVisibleIcons = isLandscape 
      ? ((screenWidth - 200) / 50).floor()
      : ((screenWidth - 150) / 50).floor();

  return AppBar(
    title: Text(title),
    centerTitle: true,
    backgroundColor: Colors.lightBlue[300],
    elevation: 0,
    actions: _buildResponsiveActions(context, maxVisibleIcons), // ✅ Pass maxVisibleIcons (not maxVisible)
  );
}

  List<Widget> _buildResponsiveActions(BuildContext context, int maxVisible) {
    // Definisikan semua actions dengan prioritas
    final allActions = [
      _ActionItem(
        priority: 1, // HIGHEST - selalu tampil
        icon: Icons.dashboard,
        label: 'Dashboard',
        onTap: onDashboard,
        color: Colors.white,
      ),
      _ActionItem(
        priority: 2,
        icon: Icons.receipt_long,
        label: 'Receipts',
        onTap: onReceipts,
        badge: receiptsCount,
        color: Colors.white,
      ),
      _ActionItem(
        priority: 3,
        icon: Icons.history,
        label: 'History',
        onTap: onHistory,
        badge: historyCount,
        color: Colors.white,
      ),
      _ActionItem(
        priority: 4,
        icon: Icons.settings,
        label: 'Settings',
        onTap: onSettings,
        color: Colors.white,
      ),
      _ActionItem(
        priority: 5,
        icon: Icons.inventory_2,
        label: 'Barang',
        onTap: onBarangList,
        color: Colors.white,
      ),
      _ActionItem(
        priority: 6,
        icon: Icons.label,
        label: 'Label Designer',
        onTap: onLabelDesigner,
        color: Colors.white,
      ),
      _ActionItem(
        priority: 7,
        icon: showRawData ? Icons.monitor : Icons.monitor_outlined,
        label: 'Raw Data',
        onTap: onToggleRawData,
        color: Colors.white,
      ),
      _ActionItem(
        priority: 8,
        icon: Icons.storage,
        label: 'Database',
        onTap: onDatabaseViewer,
        color: Colors.white,
      ),
    ];

    // Sort by priority
    allActions.sort((a, b) => a.priority.compareTo(b.priority));

    // Split: visible vs overflow
    final visibleActions = allActions.take(maxVisible - 1).toList(); // -1 untuk more button
    final overflowActions = allActions.skip(maxVisible - 1).toList();

    final widgets = <Widget>[];

    // Tambahkan visible actions
    for (var action in visibleActions) {
      widgets.add(_buildIconButton(action));
    }

    // Tambahkan overflow menu jika ada
    if (overflowActions.isNotEmpty) {
      widgets.add(_buildOverflowMenu(context, overflowActions));
    }

    return widgets;
  }

  Widget _buildIconButton(_ActionItem action) {
    if (action.badge != null && action.badge! > 0) {
      return Badge(
        label: Text('${action.badge}'),
        backgroundColor: Colors.red,
        child: IconButton(
          icon: Icon(action.icon),
          onPressed: action.onTap,
          tooltip: action.label,
          color: action.color,
        ),
      );
    }

    return IconButton(
      icon: Icon(action.icon),
      onPressed: action.onTap,
      tooltip: action.label,
      color: action.color,
    );
  }

  Widget _buildOverflowMenu(BuildContext context, List<_ActionItem> actions) {
    return PopupMenuButton<VoidCallback>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'More options',
      onSelected: (callback) => callback(),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<VoidCallback>>[];

        // Menu items dari overflow actions
        for (var action in actions) {
          items.add(
            PopupMenuItem<VoidCallback>(
              value: action.onTap,
              child: Row(
                children: [
                  Icon(action.icon, size: 20),
                  const SizedBox(width: 12),
                  Text(action.label),
                  if (action.badge != null && action.badge! > 0) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${action.badge}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        // ═════════════════════════════════════════════════════
        // ✅ NEW: STATISTICAL SESSION MENU (FIRST ITEM!)
        // ═════════════════════════════════════════════════════
        items.add(const PopupMenuDivider());
        
        if (onStatisticalSession != null) {
          items.add(
            PopupMenuItem<VoidCallback>(
              value: onStatisticalSession,
              child: Row(
                children: [
                  Icon(
                    Icons.analytics,
                    size: 20,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Statistical Session',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          );
          items.add(const PopupMenuDivider());
        }
        // ═════════════════════════════════════════════════════

        // Advanced menu (print, command, dll)
        items.addAll([
          PopupMenuItem<VoidCallback>(
            value: onRequestPrint,
            child: const Row(
              children: [
                Icon(Icons.print, size: 20),
                SizedBox(width: 12),
                Text('Request PRINT'),
              ],
            ),
          ),
          PopupMenuItem<VoidCallback>(
            value: onPrintLog,
            child: const Row(
              children: [
                Icon(Icons.history, size: 20),
                SizedBox(width: 12),
                Text('Log PRINT'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<VoidCallback>(
            value: onSendCommand,
            child: const Row(
              children: [
                Icon(Icons.send, size: 20),
                SizedBox(width: 12),
                Text('Kirim Perintah'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          
          // ═════════════════════════════════════════════════════
          // PRINT TOGGLE MENU ITEM
          // ═════════════════════════════════════════════════════
          PopupMenuItem<VoidCallback>(
            value: onTogglePrint ?? () {}, // Use empty callback if null
            child: Row(
              children: [
                Icon(
                  isPrintEnabled ? Icons.print : Icons.print_disabled,
                  size: 20,
                  color: isPrintEnabled ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  isPrintEnabled ? 'Disable Printing' : 'Enable Printing',
                  style: TextStyle(
                    color: isPrintEnabled ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          // ═════════════════════════════════════════════════════
          
          PopupMenuItem<VoidCallback>(
            value: onChangePrinter,
            child: Row(
              children: [
                const Icon(Icons.print_outlined, size: 20, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Ubah Printer Default',
                        style: TextStyle(color: Colors.blue),
                      ),
                      if (defaultPrinterName != null)
                        Text(
                          'Saat ini: $defaultPrinterName',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        const Text(
                          'Belum ada printer default',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]);

        return items;
      },
    );
  }
}

/// Model untuk action item dengan prioritas
class _ActionItem {
  final int priority;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badge;
  final Color color;

  _ActionItem({
    required this.priority,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.color = Colors.black,
  });
}