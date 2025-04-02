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
        title: const Row(
          children: [
            Icon(Icons.monetization_on, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'Market Rates',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
        children: const [CurrentRatesTab(), HistoryTab()],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D47A1),
        onPressed: () => _showAddMetalDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
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

class CurrentRatesTab extends StatelessWidget {
  const CurrentRatesTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen width to make layout responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 400;

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
        }

        return SingleChildScrollView(
          child: Padding(
            // Reduce padding on smaller screens
            padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today's date display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Today's Rates",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateString,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                ...groupedMetals.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _getIconForType(entry.key),
                          const SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: TextStyle(
                              // Make font size responsive
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D47A1),
                            ),
                          ),
                        ],
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          // Adjust number of columns based on screen width
                          crossAxisCount: isTablet ? 3 : 2,
                          // Make cards more compact on mobile
                          childAspectRatio:
                              isMobile ? 3.0 : (isTablet ? 3.5 : 2.7),
                          crossAxisSpacing: isMobile ? 8 : 16,
                          mainAxisSpacing: isMobile ? 8 : 16,
                        ),
                        itemCount: entry.value.length,
                        itemBuilder:
                            (context, index) => _buildMetalCard(
                              context,
                              entry.value[index],
                              isMobile,
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
                // Add extra padding at the bottom to prevent overflow
                SizedBox(height: isMobile ? 90 : 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'gold':
        return const Icon(Icons.monetization_on, color: Colors.amber);
      case 'silver':
        return const Icon(Icons.monetization_on, color: Colors.grey);
      case 'platinum':
        return const Icon(Icons.monetization_on, color: Colors.blueGrey);
      case 'diamond':
        return const Icon(Icons.diamond, color: Colors.lightBlueAccent);
      default:
        return const Icon(Icons.category, color: Color(0xFF0D47A1));
    }
  }

  // Update _buildMetalCard to accept responsive flag
  Widget _buildMetalCard(
    BuildContext context,
    DocumentSnapshot document,
    bool isMobile,
  ) {
    final data = document.data() as Map<String, dynamic>;
    final NumberFormat currencyFormat = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    );

    // Create glassy effect container with responsive sizing
    return ClipRRect(
      borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.6),
                Colors.white.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            // Reduce padding on mobile
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 8 : 12,
              horizontal: isMobile ? 8 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 13 : 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (data['timestamp'] != null)
                      Flexible(
                        child: Text(
                          DateFormat(
                            isMobile ? 'MMM d' : 'MMM d, y',
                          ).format((data['timestamp'] as Timestamp).toDate()),
                          style: TextStyle(
                            fontSize: isMobile ? 9 : 11,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currencyFormat.format(data['price']),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D47A1),
                            fontSize: isMobile ? 13 : 15,
                          ),
                        ),
                        IconButton(
                          constraints: BoxConstraints(
                            // Make icon button more compact
                            minWidth: isMobile ? 20 : 30,
                            minHeight: isMobile ? 20 : 30,
                          ),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.edit,
                            color: const Color(0xFF0D47A1),
                            size: isMobile ? 16 : 20,
                          ),
                          onPressed: () => _showEditDialog(context, document),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final TextEditingController controller = TextEditingController(
      text: data['price'].toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                const Icon(Icons.edit, color: Color(0xFF0D47A1)),
                const SizedBox(width: 10),
                Text('Edit ${data['name']} Price'),
              ],
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'New Price',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
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
                ),
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    try {
                      await document.reference.update({
                        'price': int.parse(controller.text),
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Price updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating price: $e')),
                        );
                      }
                    }
                  }
                },
                label: const Text(
                  'Save',
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 400;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('metals')
              .orderBy('timestamp', descending: false)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data!.docs;

        if (allDocs.isEmpty) {
          return const Center(child: Text('No price history available yet.'));
        }

        // Process data for chart
        final Map<String, List<ChartData>> chartDataMap = {};
        final Set<String> allDates = {};

        for (var doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['timestamp'] == null) continue;

          final timestamp = data['timestamp'] as Timestamp;
          final date = DateFormat('yyyy-MM-dd').format(timestamp.toDate());

          // Skip if outside selected date range
          if (_selectedDateRange != null) {
            final docDate = timestamp.toDate();
            if (docDate.isBefore(_selectedDateRange!.start) ||
                docDate.isAfter(
                  _selectedDateRange!.end.add(const Duration(days: 1)),
                )) {
              continue;
            }
          }

          allDates.add(date);

          final name = data['name'] as String;
          chartDataMap.putIfAbsent(name, () => []);

          // Check if price exists and is valid
          if (data['price'] != null) {
            final price =
                (data['price'] is int)
                    ? data['price'].toDouble()
                    : (data['price'] is double)
                    ? data['price']
                    : 0.0;

            // Check if we already have an entry for this date
            final existingIndex = chartDataMap[name]!.indexWhere(
              (item) => item.date == date,
            );

            if (existingIndex >= 0) {
              // Update existing entry if this timestamp is newer
              final existingData = chartDataMap[name]![existingIndex];
              if (timestamp.seconds > existingData.timestamp.seconds) {
                chartDataMap[name]![existingIndex] = ChartData(
                  date,
                  price,
                  timestamp,
                );
              }
            } else {
              // Add new entry
              chartDataMap[name]!.add(ChartData(date, price, timestamp));
            }
          }
        }

        // Sort each metal's data by date
        for (var entry in chartDataMap.entries) {
          entry.value.sort((a, b) => a.date.compareTo(b.date));
        }

        // Remove entries with fewer than 2 data points
        chartDataMap.removeWhere((key, value) => value.length < 2);

        if (chartDataMap.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.timeline_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text('Not enough price history data to display trends.'),
                const SizedBox(height: 24),
                if (_selectedDateRange != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Date Filter'),
                    onPressed: () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                    },
                  ),
              ],
            ),
          );
        }

        // Convert to FL Chart data format
        List<String> sortedDates = allDates.toList()..sort();

        // Create a color palette for the lines
        final List<Color> lineColors = [
          Colors.blue,
          Colors.red,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.teal,
          Colors.amber,
          Colors.pink,
        ];

        // Create LineBarData for each metal
        final List<LineChartBarData> lineBarsData = [];
        final List<String> legendTitles = [];

        int colorIndex = 0;
        chartDataMap.forEach((metalName, dataPoints) {
          final spots =
              dataPoints.map((point) {
                final xValue = sortedDates.indexOf(point.date).toDouble();
                return FlSpot(xValue, point.price);
              }).toList();

          if (spots.isNotEmpty) {
            final color = lineColors[colorIndex % lineColors.length];
            lineBarsData.add(
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: color,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
              ),
            );
            legendTitles.add(metalName);
            colorIndex++;
          }
        });

        // Calculate date range string
        String dateRangeText =
            _selectedDateRange != null
                ? '${DateFormat('MMM d, y').format(_selectedDateRange!.start)} - '
                    '${DateFormat('MMM d, y').format(_selectedDateRange!.end)}'
                : 'All Time';

        return SafeArea(
          // Add bottom padding to prevent overflow
          bottom: true,
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
            child: Column(
              children: [
                // Date range selection bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF0D47A1),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dateRangeText,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: const Text('Change'),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange:
                                _selectedDateRange ??
                                DateTimeRange(
                                  start: DateTime.now().subtract(
                                    const Duration(days: 30),
                                  ),
                                  end: DateTime.now(),
                                ),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF0D47A1),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDateRange = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Daily Price Trends',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Legend section with more compact layout on mobile
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 4 : 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: isMobile ? 8 : 16,
                        runSpacing: isMobile ? 4 : 8,
                        children: List.generate(
                          lineColors.length < legendTitles.length
                              ? lineColors.length
                              : legendTitles.length,
                          (i) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: lineColors[i % lineColors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  legendTitles[i],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Chart area with responsive height constraint
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(
                      // Set maximum height to prevent overflow
                      maxHeight: screenHeight * (isMobile ? 0.4 : 0.5),
                    ),
                    child: LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.white.withOpacity(0.8),
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((
                                LineBarSpot touchedSpot,
                              ) {
                                final date = sortedDates[touchedSpot.x.toInt()];
                                final formattedPrice = NumberFormat.currency(
                                  symbol: '₹',
                                  decimalDigits: 0,
                                ).format(touchedSpot.y);

                                return LineTooltipItem(
                                  '$date\n$formattedPrice',
                                  const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                          handleBuiltInTouches: true,
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 1000,
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                if (value < 0 || value >= sortedDates.length) {
                                  return const SizedBox();
                                }
                                // Show dates at regular intervals to prevent crowding
                                if (value.toInt() %
                                            ((sortedDates.length / 5).ceil()) !=
                                        0 &&
                                    value != sortedDates.length - 1) {
                                  return const SizedBox();
                                }
                                final date = sortedDates[value.toInt()];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('MMM d').format(
                                      DateFormat('yyyy-MM-dd').parse(date),
                                    ),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            axisNameWidget: const Text('Price (₹)'),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  NumberFormat.compact().format(value),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: const Color(0xff37434d),
                            width: 1,
                          ),
                        ),
                        minX: 0,
                        maxX: sortedDates.length - 1.0,
                        lineBarsData: lineBarsData,
                      ),
                    ),
                  ),
                ),

                // Add bottom padding to prevent overflow with FAB
                const SizedBox(height: 16),
              ],
            ),
          ),
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
