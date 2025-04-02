import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
// For theme controller
import 'dart:math' show pi, cos, sin; // Fixed import for math functions

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  final List<Map<String, dynamic>> _salesData = [
    {'month': 'Jan', 'sales': 450000, 'cost': 320000},
    {'month': 'Feb', 'sales': 520000, 'cost': 380000},
    {'month': 'Mar', 'sales': 680000, 'cost': 450000},
    {'month': 'Apr', 'sales': 720000, 'cost': 490000},
    {'month': 'May', 'sales': 890000, 'cost': 550000},
    {'month': 'Jun', 'sales': 950000, 'cost': 620000},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 120 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 120 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  bool _isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  double get _totalSales =>
      _salesData.isEmpty
          ? 0
          : _salesData.fold(0, (sum, item) => sum + (item['sales'] as num));

  double get _totalProfit =>
      _salesData.isEmpty
          ? 0
          : _salesData.fold(
            0,
            (sum, item) =>
                sum + ((item['sales'] as num) - (item['cost'] as num)),
          );

  double get _profitMargin =>
      _totalSales == 0 ? 0 : (_totalProfit / _totalSales) * 100;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _isDarkMode(context);

    final textPrimaryColor =
        isDarkMode ? Colors.white : Colors.indigo[900] ?? Colors.indigo;
    final textSecondaryColor =
        isDarkMode
            ? Colors.grey[300] ?? Colors.grey[200]
            : Colors.grey[700] ?? Colors.grey[600];
    final cardColor =
        isDarkMode ? Colors.grey[850] ?? const Color(0xFF303030) : Colors.white;
    final chartBgColor =
        isDarkMode
            ? Colors.grey[800] ?? const Color(0xFF424242)
            : Colors.grey[100] ?? const Color(0xFFF5F5F5);
    final dividerColor =
        isDarkMode
            ? Colors.grey[700] ?? const Color(0xFF616161)
            : Colors.grey[300] ?? const Color(0xFFE0E0E0);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: true, // Show back button
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
              ), // White back icon
              onPressed: () => Navigator.of(context).pop(),
            ),
            backgroundColor:
                _isScrolled ? const Color(0xFF0D47A1) : Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Analytics',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              background: _buildAppBarBackground(),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              kIsWeb ? 50 : 30, // Smaller bottom padding on mobile
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKeyMetrics(textPrimaryColor),
                  SizedBox(height: kIsWeb ? 30 : 20), // Smaller gap on mobile
                  Builder(
                    builder: (context) {
                      try {
                        return _buildSalesChart(textPrimaryColor, chartBgColor);
                      } catch (e) {
                        debugPrint('Chart rendering error: $e');
                        return Center(
                          child: Text(
                            'Error rendering chart',
                            style: TextStyle(color: textPrimaryColor),
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: kIsWeb ? 30 : 20), // Smaller gap on mobile
                  Builder(
                    builder: (context) {
                      try {
                        return _buildProfitAnalysis(
                          textPrimaryColor,
                          dividerColor,
                        );
                      } catch (e) {
                        debugPrint('Chart rendering error: $e');
                        return Center(
                          child: Text(
                            'Error rendering chart',
                            style: TextStyle(color: textPrimaryColor),
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: kIsWeb ? 30 : 20), // Smaller gap on mobile
                  Builder(
                    builder: (context) {
                      try {
                        return _buildInventoryDistribution(
                          textPrimaryColor,
                          chartBgColor,
                        );
                      } catch (e) {
                        debugPrint('Chart rendering error: $e');
                        return Center(
                          child: Text(
                            'Error rendering chart',
                            style: TextStyle(color: textPrimaryColor),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarBackground() {
    return Stack(
      children: [
        // Background image
        FadeInImage(
          placeholder: const AssetImage('assets/placeholder.png'),
          image: const AssetImage('assets/jewelry_background.jpg'),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          imageErrorBuilder: (context, error, stackTrace) {
            // Fallback to gradient if image fails
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo[900] ?? Colors.indigo,
                    Colors.indigo[700] ?? Colors.indigo,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            );
          },
        ),
        // Overlay gradient for better text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.3),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMetrics(Color titleColor) {
    // Calculate profit margin amount
    final profitMarginAmount =
        _totalSales == 0 ? "0" : "रु ${_totalProfit.toStringAsFixed(0)}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color:
                titleColor ??
                (_isDarkMode(context) ? Colors.white : Colors.indigo),
          ),
        ),
        // Match spacing with other sections - use 20 consistently
        SizedBox(height: kIsWeb ? 20 : 15), // Smaller internal gap on mobile
        // Use a responsive grid layout
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: kIsWeb ? 3 : 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: kIsWeb ? 2.2 : 1.3,
          ),
          itemCount: 3,
          itemBuilder: (context, index) {
            // Define metrics with icons for better visualization
            final metrics = [
              {
                'title': 'Total Sales',
                'value': 'रु ${_totalSales.toStringAsFixed(0)}',
                'color': Colors.green,
                'icon': Icons.arrow_circle_up,
              },
              {
                'title': 'Total Profit',
                'value': 'रु ${_totalProfit.toStringAsFixed(0)}',
                'color': Colors.blue,
                'icon': Icons.account_balance_wallet,
              },
              {
                'title': 'Profit Margin',
                'value': '${_profitMargin.toStringAsFixed(1)}%',
                'subvalue': profitMarginAmount,
                'color': Colors.purple,
                'icon': Icons.pie_chart,
              },
            ];

            // Colors for dark/light mode
            Color metricColor;
            if (_isDarkMode(context)) {
              if (metrics[index]['color'] == Colors.green) {
                metricColor = Colors.greenAccent;
              } else if (metrics[index]['color'] == Colors.blue) {
                metricColor = Colors.lightBlueAccent;
              } else {
                metricColor = Colors.purpleAccent;
              }
            } else {
              metricColor = metrics[index]['color'] as Color;
            }

            return Container(
              decoration: BoxDecoration(
                color:
                    (_isDarkMode(context)
                        ? (metrics[index]['color'] as Color).withOpacity(0.15)
                        : (metrics[index]['color'] as Color).withOpacity(0.08)),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Icon on the left
                    Container(
                      height: kIsWeb ? 50 : 40,
                      width: kIsWeb ? 50 : 40,
                      decoration: BoxDecoration(
                        color:
                            (_isDarkMode(context)
                                ? (metrics[index]['color'] as Color)
                                    .withOpacity(0.2)
                                : (metrics[index]['color'] as Color)
                                    .withOpacity(0.15)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        metrics[index]['icon'] as IconData,
                        color: metricColor,
                        size: kIsWeb ? 28 : 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            metrics[index]['title'] as String,
                            style: TextStyle(
                              color:
                                  _isDarkMode(context)
                                      ? Colors.white70
                                      : Colors.grey[700],
                              fontSize: kIsWeb ? 14 : 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metrics[index]['value'] as String,
                            style: TextStyle(
                              color:
                                  _isDarkMode(context)
                                      ? Colors.white
                                      : Colors.grey[800],
                              fontSize: kIsWeb ? 20 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Show subvalue only for profit margin
                          if (index == 2 &&
                              metrics[index].containsKey('subvalue'))
                            Text(
                              metrics[index]['subvalue'] as String,
                              style: TextStyle(
                                color: metricColor,
                                fontSize: kIsWeb ? 14 : 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSalesChart(Color titleColor, Color chartBgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sales Trend',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        SizedBox(height: kIsWeb ? 20 : 15), // Smaller internal gap on mobile
        Container(
          height:
              MediaQuery.of(context).size.height * 0.25, // 25% of screen height
          padding: EdgeInsets.all(
            kIsWeb ? 15 : 12,
          ), // Smaller padding on mobile
          decoration: BoxDecoration(
            color: chartBgColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child:
              _salesData.isEmpty
                  ? Center(
                    child: Text(
                      'No sales data available',
                      style: TextStyle(color: titleColor),
                    ),
                  )
                  : CustomPaint(
                    size: Size.infinite,
                    painter: _SalesChartPainter(
                      data: _salesData,
                      isDarkMode: _isDarkMode(context),
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildProfitAnalysis(Color titleColor, Color dividerColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profit Analysis',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        SizedBox(height: kIsWeb ? 20 : 15), // Smaller internal gap on mobile
        SizedBox(
          // Fixed height instead of percentage
          height: 250, // Fixed height that works on most devices
          child:
              _salesData.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'No profit data available',
                        style: TextStyle(color: titleColor),
                      ),
                    ),
                  )
                  : ListView.separated(
                    physics:
                        const ClampingScrollPhysics(), // Prevent overscrolling
                    itemCount: _salesData.length,
                    separatorBuilder:
                        (context, index) => Divider(color: dividerColor),
                    itemBuilder: (context, index) {
                      final profit =
                          (_salesData[index]['sales'] as num) -
                          (_salesData[index]['cost'] as num);
                      return ListTile(
                        title: Text(
                          _salesData[index]['month'] as String,
                          style: TextStyle(color: titleColor),
                        ),
                        trailing: Text(
                          'रु ${profit.toStringAsFixed(0)}',
                          style: TextStyle(
                            color:
                                profit > 0
                                    ? (_isDarkMode(context)
                                        ? Colors.greenAccent
                                        : Colors.green)
                                    : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: LinearProgressIndicator(
                          value: _totalProfit == 0 ? 0 : profit / _totalProfit,
                          backgroundColor:
                              _isDarkMode(context)
                                  ? Colors.grey[700] ?? Colors.grey
                                  : Colors.grey[300] ?? Colors.grey[200],
                          color:
                              _isDarkMode(context)
                                  ? Colors.lightBlueAccent
                                  : Colors.blue,
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildInventoryDistribution(Color titleColor, Color chartBgColor) {
    final inventory = {
      'Gold': 45.0,
      'Silver': 30.0,
      'Diamonds': 15.0,
      'Gemstones': 10.0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Distribution',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        SizedBox(height: kIsWeb ? 20 : 15), // Smaller internal gap on mobile
        Container(
          // Fixed height to prevent layout issues on small screens
          height:
              kIsWeb
                  ? 400 // Fixed size on web
                  : 220, // Fixed smaller size on mobile
          padding: EdgeInsets.all(
            kIsWeb ? 15 : 12,
          ), // Smaller padding on mobile
          decoration: BoxDecoration(
            color: chartBgColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _InventoryPieChartPainter(
              data: inventory,
              isDarkMode: _isDarkMode(context),
              webScale: kIsWeb ? 1.5 : 0.9, // Slightly smaller on mobile
            ),
          ),
        ),
        SizedBox(height: kIsWeb ? 16 : 12), // Smaller on mobile
        Wrap(
          spacing: kIsWeb ? 16 : 12, // Smaller on mobile
          runSpacing: kIsWeb ? 8 : 6, // Smaller on mobile
          children: [
            _buildColorIndicator('Gold', Colors.amber),
            _buildColorIndicator('Silver', Colors.blueGrey),
            _buildColorIndicator('Diamonds', Colors.pink),
            _buildColorIndicator('Gemstones', Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildColorIndicator(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: _isDarkMode(context) ? Colors.white : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(String greeting, String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: GoogleFonts.poppins(
            fontSize: 18,
            color:
                _isDarkMode(context)
                    ? Colors.white70
                    : Colors.grey[600] ?? Colors.grey,
          ),
        ),
        Text(
          userName.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color:
                _isDarkMode(context)
                    ? Colors.white
                    : Colors.indigo[900] ?? Colors.indigo,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search...',
        hintStyle: TextStyle(
          color:
              _isDarkMode(context)
                  ? Colors.grey[400] ?? Colors.grey[300]
                  : null,
        ),
        prefixIcon: Icon(
          Icons.search,
          color:
              _isDarkMode(context)
                  ? Colors.grey[400] ?? Colors.grey[300]
                  : null,
        ),
        filled: true,
        fillColor:
            _isDarkMode(context)
                ? Colors.grey[800] ?? const Color(0xFF424242)
                : Colors.grey[100] ?? const Color(0xFFF5F5F5),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color:
            _isDarkMode(context)
                ? Colors.white
                : Colors.indigo[900] ?? Colors.indigo,
      ),
    );
  }
}

class _SalesChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final bool isDarkMode;

  _SalesChartPainter({required this.data, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxSales =
        data
            .map((e) => e['sales'] as num)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();
    if (maxSales == 0) return;

    final paint =
        Paint()
          ..color = isDarkMode ? Colors.lightBlueAccent : Colors.blue
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    final fillPaint =
        Paint()
          ..color =
              isDarkMode
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.1)
          ..style = PaintingStyle.fill;

    final gridPaint =
        Paint()
          ..color = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    for (var i = 0; i < 5; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < data.length; i++) {
      final x = size.width * (i / (data.length - 1));
      final y =
          size.height - (size.height * ((data[i]['sales'] as num) / maxSales));
      points.add(Offset(x, y));

      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = isDarkMode ? Colors.lightBlueAccent : Colors.blue,
      );
    }

    if (points.length > 1) {
      path.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);

      final fillPath =
          Path.from(path)
            ..lineTo(points.last.dx, size.height)
            ..lineTo(points.first.dx, size.height)
            ..close();
      canvas.drawPath(fillPath, fillPaint);
    }

    final textStyle = TextStyle(
      color: isDarkMode ? Colors.grey[300]! : Colors.grey[700]!,
      fontSize: 10,
    );
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < data.length; i++) {
      final x = size.width * (i / (data.length - 1));
      textPainter.text = TextSpan(
        text: data[i]['month'] as String,
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height + 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _InventoryPieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final bool isDarkMode;
  final double webScale; // Add this line
  final List<Color> colors = const [
    Colors.amber,
    Colors.blueGrey,
    Colors.pink,
    Colors.green,
  ];

  _InventoryPieChartPainter({
    required this.data,
    required this.isDarkMode,
    this.webScale = 1.0, // Add this parameter with default value
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final total = data.values.reduce((a, b) => a + b);
    if (total == 0) return;

    final center = size.center(Offset.zero);
    // Simplify radius calculation to avoid arithmetic errors
    final radius = (size.shortestSide * 0.4) * (webScale > 0 ? webScale : 1.0);
    final rect = Rect.fromCircle(center: center, radius: radius);

    var startAngle = -pi / 2; // -90 degrees in radians

    var i = 0;
    data.forEach((key, value) {
      // Prevent division by zero
      if (value <= 0) return;

      // Simpler angle calculation to avoid precision errors
      final sweepAngle = (value / total) * 2 * pi;
      final paint =
          Paint()
            ..color = colors[i % colors.length]
            ..style = PaintingStyle.fill;

      // Draw the arc safely
      try {
        canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

        // Show percentages on all devices
        try {
          final midAngle = startAngle + sweepAngle / 2;
          final x = center.dx + (radius * 0.7) * cos(midAngle);
          final y = center.dy + (radius * 0.7) * sin(midAngle);

          // Only show percentages for segments that are large enough
          if (sweepAngle > 0.3) {
            // Skip tiny segments
            final percentage = (value / total * 100).toStringAsFixed(0);
            final textPainter = TextPainter(
              text: TextSpan(
                text: '$percentage%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: kIsWeb ? 14 : 12, // Smaller on mobile
                  fontWeight: FontWeight.bold,
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            textPainter.paint(
              canvas,
              Offset(x - textPainter.width / 2, y - textPainter.height / 2),
            );
          }
        } catch (e) {
          debugPrint('Text rendering error: $e');
        }
      } catch (e) {
        debugPrint('Drawing error: $e');
      }

      startAngle += sweepAngle;
      i++;
    });

    // Draw center circle safely
    try {
      canvas.drawCircle(
        center,
        radius / 2.5, // Slightly smaller for better appearance
        Paint()
          ..color = isDarkMode ? Colors.grey[850] ?? Colors.black : Colors.white
          ..style = PaintingStyle.fill,
      );
    } catch (e) {
      debugPrint('Center circle error: $e');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
