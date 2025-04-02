import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // For ImageFilter

class RateScreen extends StatefulWidget {
  const RateScreen({super.key});

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
  );
  bool _isEditMode = false;
  final GlobalKey<_CurrentRatesTabState> _currentRatesTabKey =
      GlobalKey<_CurrentRatesTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Add listener to hide buttons when on History tab
    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.animation!.value != _tabController.index) {
        setState(() {
          // This ensures UI updates when tab changes
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // Center the title
        title: const Text(
          'Today\'s Price',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 4,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor:
              Colors.white70, // Add this line for better visibility
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ), // Make active tab bold
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
          ), // Normal weight for inactive
          indicatorWeight:
              3, // Slightly thicker indicator for better visibility
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Current Rates'),
            Tab(icon: Icon(Icons.trending_up), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CurrentRatesTab(key: _currentRatesTabKey),
          const HistoryTab(),
        ],
      ),
      floatingActionButton:
          _tabController.index == 0
              ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit button - positioned above Add button
                  if (!_isEditMode) // Only show when not in edit mode
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FloatingActionButton(
                        heroTag: "editBtn",
                        backgroundColor: const Color(
                          0xFF0D47A1,
                        ), // Same color as add button
                        onPressed: () {
                          setState(() {
                            _isEditMode = true;
                            // Send message to CurrentRatesTab
                            _currentRatesTabKey.currentState?.setEditMode(true);
                          });
                        },
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                        ), // White icon
                      ),
                    ),

                  // Save button - shown during edit mode
                  if (_isEditMode)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FloatingActionButton(
                        heroTag: "saveBtn",
                        backgroundColor: Colors.green,
                        onPressed: () {
                          // Call save method in CurrentRatesTab
                          _currentRatesTabKey.currentState?.saveChanges();
                          setState(() {
                            _isEditMode = false;
                          });
                        },
                        child: const Icon(Icons.check, color: Colors.white),
                      ),
                    ),

                  // Regular add button
                  FloatingActionButton(
                    heroTag: "addBtn",
                    backgroundColor: const Color(0xFF0D47A1),
                    onPressed: () => _showAddMetalDialog(context),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              )
              : null, // Return null for History tab
    );
  }

  void _showAddMetalDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController typeController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.add_circle, color: Color(0xFF0D47A1)),
                SizedBox(width: 10),
                Text('Add New Metal'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Metal Name (e.g. Gold 24K)',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: 'Type (e.g. Gold, Silver)',
                    prefixIcon: Icon(Icons.style),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixIcon: Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      priceController.text.isNotEmpty) {
                    await _firestore.collection('metals').add({
                      'name': nameController.text,
                      'type':
                          typeController.text.isNotEmpty
                              ? typeController.text
                              : 'Other',
                      'price': int.parse(priceController.text),
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Metal added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                label: const Text('Add', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }
}

class CurrentRatesTab extends StatefulWidget {
  const CurrentRatesTab({super.key});

  @override
  State<CurrentRatesTab> createState() => _CurrentRatesTabState();
}

class _CurrentRatesTabState extends State<CurrentRatesTab> {
  bool _isEditMode = false;
  final Map<String, TextEditingController> _priceControllers = {};

  // Get color based on metal type
  Color _getColorForType(String type, int index) {
    final colorPairs = <String, List<Color>>{
      'gold': [
        const Color(0xFFFFD700).withOpacity(0.7),
        const Color(0xFFFFC000).withOpacity(0.6),
      ],
      'silver': [
        const Color(0xFFC0C0C0).withOpacity(0.7),
        const Color(0xFFD8D8D8).withOpacity(0.6),
      ],
      'platinum': [
        const Color(0xFFE5E4E2).withOpacity(0.7),
        const Color(0xFFA9A9A9).withOpacity(0.6),
      ],
      'diamond': [
        const Color(0xFFB9F2FF).withOpacity(0.7),
        const Color(0xFF89CFF0).withOpacity(0.6),
      ],
      'other': [
        const Color(0xFF90CAF9).withOpacity(0.7),
        const Color(0xFF64B5F6).withOpacity(0.6),
      ],
    };

    final lowerType = type.toLowerCase();
    final colors = colorPairs[lowerType] ?? colorPairs['other']!;
    return colors[index % 2];
  }

  void setEditMode(bool isEditMode) {
    setState(() {
      _isEditMode = isEditMode;
    });
  }

  void saveChanges() async {
    final batch = FirebaseFirestore.instance.batch();

    try {
      _priceControllers.forEach((id, controller) {
        if (controller.text.isNotEmpty) {
          final price = int.tryParse(controller.text);
          if (price != null) {
            final docRef = FirebaseFirestore.instance
                .collection('metals')
                .doc(id);
            batch.update(docRef, {
              'price': price,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All prices updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditMode = false;
          _priceControllers.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating prices: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to make layout responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 400;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('metals')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final metals = snapshot.data!.docs;

        if (metals.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No metals added yet. Add some using + button.'),
              ],
            ),
          );
        }

        // Current date display
        final today = DateTime.now();
        final dateString = DateFormat('EEEE, MMMM d, y').format(today);

        // Group metals by type
        Map<String, List<DocumentSnapshot>> groupedMetals = {};
        for (var metal in metals) {
          final data = metal.data() as Map<String, dynamic>;
          final type = data['type'] as String? ?? 'Other';
          if (!groupedMetals.containsKey(type)) {
            groupedMetals[type] = [];
          }
          groupedMetals[type]!.add(metal);

          // Initialize price controllers if in edit mode
          if (_isEditMode) {
            _priceControllers[metal.id] = TextEditingController(
              text: data['price'].toString(),
            );
          }
        }

        // Use a Column with fixed date header and scrollable content
        return Column(
          children: [
            // Fixed date header (non-scrollable)
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 6.0 : 12.0,
                isMobile ? 6.0 : 12.0,
                isMobile ? 6.0 : 12.0,
                0,
              ),
              child: Container(
                width: double.infinity,
                height: isMobile ? 38 : 40,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 6 : 8,
                ),
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.white70,
                      size: isMobile ? 14 : 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateString,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: isMobile ? 11 : 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable content (metal groups)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 6.0 : 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...groupedMetals.entries.map((entry) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type header - no capsule, just text with icon
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _getIconForType(entry.key),
                                  const SizedBox(width: 8),
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF0D47A1),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isMobile ? 6 : 8),
                              // More compact grid for web
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      isTablet
                                          ? 5
                                          : 2, // Increased from 4 to 5 columns for tablet/web
                                  // More compact cards for web - adjusted aspect ratio for 5 columns
                                  childAspectRatio:
                                      isTablet ? 2.2 : (isMobile ? 1.8 : 2.2),
                                  crossAxisSpacing:
                                      isTablet
                                          ? 6
                                          : 15, // Further reduced from 8 to 6 for tablet
                                  mainAxisSpacing:
                                      isTablet
                                          ? 6
                                          : 15, // Further reduced from 8 to 6 for tablet
                                ),
                                itemCount: entry.value.length,
                                itemBuilder:
                                    (context, index) => _buildMetalCard(
                                      context,
                                      entry.value[index],
                                      _getColorForType(entry.key, index),
                                      isMobile,
                                      isDarkMode,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetalCard(
    BuildContext context,
    DocumentSnapshot document,
    Color cardColor,
    bool isMobile,
    bool isDarkMode,
  ) {
    final data = document.data() as Map<String, dynamic>;
    final NumberFormat currencyFormat = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    );

    // Format the timestamp for "last updated"
    String lastUpdated = "";
    if (data['timestamp'] != null) {
      final timestamp = data['timestamp'] as Timestamp;
      final now = DateTime.now();
      final difference = now.difference(timestamp.toDate());

      if (difference.inDays == 0) {
        // Today
        if (difference.inHours == 0) {
          lastUpdated = "${difference.inMinutes} min ago";
        } else {
          lastUpdated = "${difference.inHours} hrs ago";
        }
      } else if (difference.inDays == 1) {
        // Yesterday
        lastUpdated = "Yesterday";
      } else {
        // Days ago
        lastUpdated = "${difference.inDays} days ago";
      }
    }

    // Initialize controller if in edit mode but not yet set
    if (_isEditMode && !_priceControllers.containsKey(document.id)) {
      _priceControllers[document.id] = TextEditingController(
        text: data['price'].toString(),
      );
    }

    // More compact card for web
    final isTablet = MediaQuery.of(context).size.width > 600;
    final padding = isTablet ? 8.0 : (isMobile ? 12.0 : 10.0);

    return Container(
      decoration: BoxDecoration(
        color:
            (_isDarkMode(context)
                ? cardColor.withOpacity(_isEditMode ? 0.25 : 0.15)
                : cardColor.withOpacity(_isEditMode ? 0.15 : 0.08)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isEditMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            _isEditMode
                ? Border.all(
                  color: cardColor.withOpacity(isDarkMode ? 0.3 : 0.5),
                  width: 1,
                )
                : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          children: [
            // Icon on the left - smaller for web
            Container(
              height: isTablet ? 36 : (isMobile ? 40 : 46),
              width: isTablet ? 36 : (isMobile ? 40 : 46),
              decoration: BoxDecoration(
                color:
                    (_isDarkMode(context)
                        ? cardColor.withOpacity(0.2)
                        : cardColor.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.monetization_on,
                color: cardColor,
                size: isTablet ? 20 : (isMobile ? 22 : 24),
              ),
            ),
            SizedBox(width: isTablet ? 8 : 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Metal name with delete button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['name'],
                          style: TextStyle(
                            color:
                                _isDarkMode(context)
                                    ? Colors.white70
                                    : Colors.grey[700],
                            fontSize: isTablet ? 12 : (isMobile ? 12 : 14),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Show delete button only in edit mode
                      if (_isEditMode)
                        InkWell(
                          onTap:
                              () => _showDeleteConfirmation(context, document),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red[300],
                              size: isTablet ? 14 : (isMobile ? 16 : 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 2 : 4),

                  // Price input field or text with last updated
                  if (_isEditMode)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 4 : 6,
                          horizontal: isTablet ? 8 : 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              cardColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                              cardColor.withOpacity(isDarkMode ? 0.15 : 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: cardColor.withOpacity(
                              isDarkMode ? 0.4 : 0.3,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Currency symbol
                            Text(
                              '₹',
                              style: TextStyle(
                                fontSize: isTablet ? 13 : (isMobile ? 14 : 16),
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode
                                        ? Colors.white
                                        : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Price input
                            Expanded(
                              child: TextField(
                                controller: _priceControllers[document.id],
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize:
                                      isTablet ? 13 : (isMobile ? 14 : 16),
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.grey[800],
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: 'Enter price',
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    isTablet
                        ? // Web/tablet layout - price and date with better spacing
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Price on left
                            Text(
                              currencyFormat.format(data['price']),
                              style: TextStyle(
                                color:
                                    _isDarkMode(context)
                                        ? Colors.white
                                        : Colors.grey[800],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // Last updated on right with proper alignment
                            if (data['timestamp'] != null)
                              Container(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  DateFormat('yyyy, MMM d').format(
                                    (data['timestamp'] as Timestamp).toDate(),
                                  ),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color:
                                        isDarkMode
                                            ? Colors.white70
                                            : Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        )
                        : // Mobile layout - price and last updated stacked
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price in large font
                            Text(
                              currencyFormat.format(data['price']),
                              style: TextStyle(
                                color:
                                    _isDarkMode(context)
                                        ? Colors.white
                                        : Colors.grey[800],
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // Last updated below price
                            if (data['timestamp'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  "last updated: ${DateFormat('yyyy, MMM d').format((data['timestamp'] as Timestamp).toDate())}",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color:
                                        isDarkMode
                                            ? Colors.white70
                                            : Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to determine if dark mode is active
  bool _isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _getIconColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.grey;
      case 'platinum':
        return Colors.blueGrey;
      case 'diamond':
        return Colors.lightBlueAccent;
      default:
        return const Color(0xFF0D47A1);
    }
  }

  Widget _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'gold':
        return const Icon(Icons.monetization_on, color: Colors.amber, size: 16);
      case 'silver':
        return const Icon(Icons.monetization_on, color: Colors.grey, size: 16);
      case 'platinum':
        return const Icon(
          Icons.monetization_on,
          color: Colors.blueGrey,
          size: 16,
        );
      case 'diamond':
        return const Icon(
          Icons.diamond,
          color: Colors.lightBlueAccent,
          size: 16,
        );
      default:
        return const Icon(Icons.category, color: Color(0xFF0D47A1), size: 16);
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    DocumentSnapshot document,
  ) {
    final data = document.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 10),
                Text('Confirm Delete'),
              ],
            ),
            content: Text('Are you sure you want to delete ${data['name']}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete, color: Colors.white),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  try {
                    await document.reference.delete();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Metal deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting metal: $e')),
                      );
                    }
                  }
                },
                label: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  // Date range for filtering
  DateTime _selectedDate = DateTime.now();
  Map<String, List<ChartData>> _chartDataByType = {};
  List<Color> _chartColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
    Colors.deepOrange,
    Colors.lime,
    Colors.lightBlue,
    Colors.deepPurple,
    Colors.brown,
    Colors.indigoAccent,
    Colors.lightGreen,
    Colors.redAccent,
  ];
  bool _isLoading = true;
  double _maxY = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with 15 days data
    _fetchPriceHistoryData();
  }

  Future<void> _fetchPriceHistoryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate date range
      final DateTime endDate = DateTime.now();
      final DateTime startDate = endDate.subtract(const Duration(days: 15));

      // First get metal types to reduce query load
      final typesSnapshot =
          await FirebaseFirestore.instance.collection('metals').get();

      if (typesSnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get unique metal names to query
      Set<String> uniqueMetalNames = {};
      for (var doc in typesSnapshot.docs) {
        uniqueMetalNames.add(doc['name'] as String);
      }

      // Process in smaller batches to avoid timeouts
      Map<String, List<ChartData>> chartData = {};
      double maxPrice = 0;

      // Process in batches of 5 metals at a time
      List<String> metalNamesList = uniqueMetalNames.toList();
      for (int i = 0; i < metalNamesList.length; i += 5) {
        int end =
            (i + 5 < metalNamesList.length) ? i + 5 : metalNamesList.length;
        List<String> batch = metalNamesList.sublist(i, end);

        // Process each metal in the batch
        for (String metalName in batch) {
          try {
            QuerySnapshot snapshot =
                await FirebaseFirestore.instance
                    .collection('metals')
                    .where('name', isEqualTo: metalName)
                    .orderBy('timestamp', descending: false)
                    .get();

            List<ChartData> dataPoints = [];

            for (var doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['timestamp'] != null) {
                final timestamp = data['timestamp'] as Timestamp;
                final date = timestamp.toDate();

                if (date.isAfter(startDate) &&
                    date.isBefore(endDate.add(const Duration(days: 1)))) {
                  final price = (data['price'] as num).toDouble();
                  if (price > maxPrice) maxPrice = price;

                  dataPoints.add(
                    ChartData(
                      DateFormat('MM/dd').format(date),
                      price,
                      timestamp,
                    ),
                  );
                }
              }
            }

            if (dataPoints.isNotEmpty) {
              chartData[metalName] = dataPoints;
            }
          } catch (e) {
            print('Error fetching history for $metalName: $e');
          }
        }
      }

      setState(() {
        _chartDataByType = chartData;
        _maxY = maxPrice > 0 ? maxPrice * 1.1 : 100000;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching price history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 400;
    final isTablet = screenWidth > 600;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final formattedSelectedDate = DateFormat(
      'MMMM d, yyyy',
    ).format(_selectedDate);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 6.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and date selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price Trend (15 Days)',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color:
                            isDarkMode ? Colors.white : Colors.indigo.shade800,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      onPressed: _fetchPriceHistoryData,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Chart area
                Container(
                  height: isMobile ? 220 : (isTablet ? 300 : 260),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? Colors.grey.shade800.withOpacity(0.5)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.only(
                    right: 16,
                    left: 6,
                    top: 20,
                    bottom: 12,
                  ),
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _chartDataByType.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timeline_outlined,
                                  size: 48,
                                  color:
                                      isDarkMode
                                          ? Colors.white70
                                          : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No price history data available',
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? Colors.white60
                                            : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                horizontalInterval: _maxY / 5,
                                verticalInterval: 1,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color:
                                        isDarkMode
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.2),
                                    strokeWidth: 1,
                                  );
                                },
                                getDrawingVerticalLine: (value) {
                                  return FlLine(
                                    color:
                                        isDarkMode
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.2),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      // Only show every 3rd label on mobile to prevent overlap
                                      if (isMobile &&
                                          value.toInt() % 3 != 0 &&
                                          value.toInt() != 0) {
                                        return const SizedBox();
                                      }

                                      // Find the first type with data
                                      final firstType =
                                          _chartDataByType.keys.first;
                                      final dataList =
                                          _chartDataByType[firstType]!;

                                      if (value.toInt() >= 0 &&
                                          value.toInt() < dataList.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Transform.rotate(
                                            angle: isMobile ? -0.5 : 0,
                                            child: Text(
                                              dataList[value.toInt()].date,
                                              style: TextStyle(
                                                color:
                                                    isDarkMode
                                                        ? Colors.white70
                                                        : Colors.grey.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: isMobile ? 9 : 10,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: _maxY / 5,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        '₹${value.toInt()}',
                                        style: TextStyle(
                                          color:
                                              isDarkMode
                                                  ? Colors.white70
                                                  : Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                    reservedSize: 42,
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                  color:
                                      isDarkMode
                                          ? Colors.white10
                                          : Colors.grey.shade200,
                                ),
                              ),
                              minX: 0,
                              maxX:
                                  _chartDataByType.isNotEmpty
                                      ? _chartDataByType[_chartDataByType
                                                  .keys
                                                  .first]!
                                              .length
                                              .toDouble() -
                                          1
                                      : 15,
                              minY: 0,
                              maxY: _maxY,
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  tooltipBgColor:
                                      isDarkMode
                                          ? Colors.grey.shade800.withOpacity(
                                            0.8,
                                          )
                                          : Colors.white.withOpacity(0.8),
                                  tooltipRoundedRadius: 8,
                                  getTooltipItems: (
                                    List<LineBarSpot> touchedSpots,
                                  ) {
                                    return touchedSpots.map((spot) {
                                      // Find which metal type this spot belongs to
                                      String? metalType;
                                      for (var entry
                                          in _chartDataByType.entries) {
                                        if (_chartDataByType.keys
                                                .toList()
                                                .indexOf(entry.key) ==
                                            spot.barIndex) {
                                          metalType = entry.key;
                                          break;
                                        }
                                      }

                                      if (metalType != null) {
                                        final color =
                                            _chartColors[spot.barIndex %
                                                _chartColors.length];
                                        return LineTooltipItem(
                                          '$metalType: ₹${spot.y.toInt()}',
                                          TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }
                                      return null;
                                    }).toList();
                                  },
                                ),
                              ),
                              lineBarsData: _buildLineBarsData(),
                            ),
                          ),
                ),

                // Legend for chart lines
                if (_chartDataByType.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children:
                          _chartDataByType.keys.map((type) {
                            final colorIndex = _chartDataByType.keys
                                .toList()
                                .indexOf(type);
                            final color =
                                _chartColors[colorIndex % _chartColors.length];

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                // Date selector
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 10 : 16),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and date picker row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Historical Prices',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),

                            // Date selector
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.light().copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Color(0xFF0D47A1),
                                          onPrimary: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null && picked != _selectedDate) {
                                  setState(() {
                                    _selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0D47A1,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF0D47A1,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color:
                                          isDarkMode
                                              ? Colors.blue.shade300
                                              : const Color(0xFF0D47A1),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      formattedSelectedDate,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isDarkMode
                                                ? Colors.blue.shade300
                                                : const Color(0xFF0D47A1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Historical prices with FutureBuilder instead of StreamBuilder for better control
                        Expanded(
                          child: FutureBuilder<QuerySnapshot>(
                            // Filter query by the selected date
                            future: () {
                              // Create date range for the selected date (start of day to end of day)
                              final startOfDay = DateTime(
                                _selectedDate.year,
                                _selectedDate.month,
                                _selectedDate.day,
                              );
                              final endOfDay = DateTime(
                                _selectedDate.year,
                                _selectedDate.month,
                                _selectedDate.day,
                                23,
                                59,
                                59,
                                999,
                              );

                              // Convert to Firestore timestamps
                              final startTimestamp = Timestamp.fromDate(
                                startOfDay,
                              );
                              final endTimestamp = Timestamp.fromDate(endOfDay);

                              return FirebaseFirestore.instance
                                  .collection('metals')
                                  .orderBy('timestamp', descending: false)
                                  .where(
                                    'timestamp',
                                    isGreaterThanOrEqualTo: startTimestamp,
                                  )
                                  .where(
                                    'timestamp',
                                    isLessThanOrEqualTo: endTimestamp,
                                  )
                                  .get();
                            }(),
                            builder: (context, snapshot) {
                              // Loading state
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              // Error handling
                              if (snapshot.hasError) {
                                print(
                                  "Error loading historical prices: ${snapshot.error}",
                                );
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Error loading data: ${snapshot.error.toString().split(']').last}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () => setState(() {}),
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0D47A1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // No data state - specifically for selected date
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 64,
                                        color:
                                            isDarkMode
                                                ? Colors.white60
                                                : Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No price history found for ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color:
                                              isDarkMode
                                                  ? Colors.white70
                                                  : Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          // Reset to today's date
                                          setState(() {
                                            _selectedDate = DateTime.now();
                                          });
                                        },
                                        icon: const Icon(Icons.today),
                                        label: const Text(
                                          "View Today's Prices",
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0D47A1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // Rest of your existing code for displaying data
                              final metals = snapshot.data!.docs;

                              // Group metals by type
                              Map<String, List<DocumentSnapshot>>
                              groupedMetals = {};
                              for (var metal in metals) {
                                final data =
                                    metal.data() as Map<String, dynamic>;
                                final type = data['type'] as String? ?? 'Other';
                                if (!groupedMetals.containsKey(type)) {
                                  groupedMetals[type] = [];
                                }
                                groupedMetals[type]!.add(metal);
                              }

                              // Create scrollable list of metal types and prices
                              return ListView(
                                children:
                                    groupedMetals.entries.map((entry) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Type header
                                          Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                              top: 12,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2,
                                              horizontal: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getColorForType(
                                                entry.key,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              entry.key,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),

                                          // Metal price cards with wrapping layout
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            children:
                                                entry.value.map((doc) {
                                                  final data =
                                                      doc.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  return _buildHistoricalPriceCard(
                                                    data['name'] as String,
                                                    data['price'] as num,
                                                    data['timestamp']
                                                        as Timestamp?,
                                                    _getColorForType(
                                                      entry.key,
                                                      opacity: 0.1,
                                                    ),
                                                    isTablet
                                                        ? 160
                                                        : (isMobile
                                                            ? 140
                                                            : 180),
                                                  );
                                                }).toList(),
                                          ),

                                          const SizedBox(height: 8),
                                        ],
                                      );
                                    }).toList(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    List<LineChartBarData> result = [];
    int colorIndex = 0;

    _chartDataByType.forEach((type, dataPoints) {
      final spots = <FlSpot>[];

      // Convert data points to spots
      for (int i = 0; i < dataPoints.length; i++) {
        spots.add(FlSpot(i.toDouble(), dataPoints[i].price));
      }

      final barData = LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        color: _chartColors[colorIndex % _chartColors.length],
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: !spots.contains(null),
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: _chartColors[colorIndex % _chartColors.length],
              strokeWidth: 1,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          color: _chartColors[colorIndex % _chartColors.length].withOpacity(
            0.15,
          ),
        ),
      );

      result.add(barData);
      colorIndex++;
    });

    return result;
  }

  Color _getColorForType(String type, {double opacity = 1.0}) {
    switch (type.toLowerCase()) {
      case 'gold':
        return Colors.amber.withOpacity(opacity);
      case 'silver':
        return Colors.blueGrey.withOpacity(opacity);
      case 'platinum':
        return Colors.grey.shade700.withOpacity(opacity);
      case 'diamond':
        return Colors.lightBlueAccent.withOpacity(opacity);
      default:
        return const Color(0xFF0D47A1).withOpacity(opacity);
    }
  }

  Widget _buildHistoricalPriceCard(
    String name,
    num price,
    Timestamp? timestamp,
    Color bgColor,
    double width,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final NumberFormat currencyFormat = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    );

    // Calculate how many days ago this price was recorded
    String timeAgo = '';
    if (timestamp != null) {
      final now = DateTime.now();
      final difference = now.difference(timestamp.toDate());

      if (difference.inDays == 0) {
        timeAgo = "Today";
      } else if (difference.inDays == 1) {
        timeAgo = "Yesterday";
      } else {
        timeAgo = "${difference.inDays} days ago";
      }
    }

    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withOpacity(0.5) : bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metal name
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          // Price
          Text(
            currencyFormat.format(price),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),

          const SizedBox(height: 4),

          // Timestamp
          if (timestamp != null)
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class ChartData {
  final String date;
  final double price;
  final Timestamp timestamp;

  ChartData(this.date, this.price, this.timestamp);
}
