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
      floatingActionButton: Column(
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
      ),
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

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 6.0 : 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full-width date container
                    Container(
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

                    ...groupedMetals.entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type header
                            Container(
                              margin: EdgeInsets.only(
                                bottom: isMobile ? 6 : 10,
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _getIconColorForType(
                                  entry.key,
                                ).withOpacity(isDarkMode ? 0.3 : 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _getIconForType(entry.key),
                                  const SizedBox(width: 6),
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF0D47A1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Enhanced grid layout with analytics-style cards
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isTablet ? 3 : 2,
                                    // More width on mobile
                                    childAspectRatio:
                                        isMobile ? 1.8 : (isTablet ? 2.2 : 2.0),
                                    crossAxisSpacing: 15,
                                    mainAxisSpacing: 15,
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
                    // Smaller bottom padding to fix overflow
                    SizedBox(height: isMobile ? 50 : 60),
                  ],
                ),
              ),
            );
          },
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

    // Initialize controller if in edit mode but not yet set
    if (_isEditMode && !_priceControllers.containsKey(document.id)) {
      _priceControllers[document.id] = TextEditingController(
        text: data['price'].toString(),
      );
    }

    // Analytics-style card with icon
    return Container(
      decoration: BoxDecoration(
        color:
            (_isDarkMode(context)
                ? cardColor.withOpacity(
                  _isEditMode ? 0.25 : 0.15,
                ) // Highlight in edit mode
                : cardColor.withOpacity(_isEditMode ? 0.15 : 0.08)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isEditMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // Add subtle border in edit mode
        border:
            _isEditMode
                ? Border.all(
                  color: cardColor.withOpacity(isDarkMode ? 0.3 : 0.5),
                  width: 1,
                )
                : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon on the left
            Container(
              height: isMobile ? 40 : 50,
              width: isMobile ? 40 : 50,
              decoration: BoxDecoration(
                color:
                    (_isDarkMode(context)
                        ? cardColor.withOpacity(0.2)
                        : cardColor.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.monetization_on,
                color: cardColor,
                size: isMobile ? 22 : 28,
              ),
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Metal name
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
                            fontSize: isMobile ? 12 : 14,
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
                              size: isMobile ? 16 : 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Price input field or text
                  if (_isEditMode)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
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
                                fontSize: isMobile ? 14 : 16,
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
                                  fontSize: isMobile ? 14 : 16,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price
                        Text(
                          currencyFormat.format(data['price']),
                          style: TextStyle(
                            color:
                                _isDarkMode(context)
                                    ? Colors.white
                                    : Colors.grey[800],
                            fontSize: isMobile ? 16 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Date
                        if (data['timestamp'] != null)
                          Text(
                            DateFormat(
                              'MMM d, y',
                            ).format((data['timestamp'] as Timestamp).toDate()),
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 11,
                              color:
                                  isDarkMode
                                      ? Colors.white54
                                      : Colors.grey[500],
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
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 400;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('metals')
              .orderBy('timestamp', descending: false)
              .snapshots(),
      builder: (context, snapshot) {
        // Rest of the function remains unchanged
        // ...

        return LayoutBuilder(
          builder: (context, constraints) {
            return SafeArea(
              bottom: true,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 6.0 : 12.0),
                child: Column(
                  children: [
                    // Date range selection bar - make more compact
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 10),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          if (!isDarkMode)
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Rest of the content remains unchanged
                          // ...
                        ],
                      ),
                    ),
                    // Rest of the content remains unchanged
                    // ...

                    // Chart area - use fixed height instead of Expanded
                    SizedBox(
                      height: constraints.maxHeight - (isMobile ? 150 : 180),
                      child: LineChart(
                        LineChartData(
                          // Add your LineChartData configuration here
                          lineBarsData: [],
                        ),
                        // LineChart configuration remains unchanged
                        // ...
                      ),
                    ),

                    // Reduced bottom padding
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ChartData {
  final String date;
  final double price;
  final Timestamp timestamp;

  ChartData(this.date, this.price, this.timestamp);
}
