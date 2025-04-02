import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/jewelry_item.dart';
import '../../models/invoice_model.dart';
import '../../services/pdf_service.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<JewelryItem> _items = [];
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerAddressController =
      TextEditingController();
  final TextEditingController _goldRateController = TextEditingController();
  final TextEditingController _goldRateTolaController = TextEditingController();
  final TextEditingController _makingChargeController = TextEditingController();
  final TextEditingController _wastageController = TextEditingController();
  final TextEditingController _advancePaymentController =
      TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  // Constants
  final double _gramsPerTola = 11.6638;
  final double _gstRate = 0.13; // 13%

  // Sale values
  double _totalAmount = 0.0;
  double _taxAmount = 0.0;
  double _discountAmount = 0.0;
  double _netAmount = 0.0;
  double _advancePayment = 0.0;
  double _balanceAmount = 0.0;
  bool _isLoading = true;
  String _paymentMode = 'Cash';
  final List<String> _paymentModes = ['Cash', 'Card', 'UPI', 'Bank Transfer'];

  // Map to store metal rates from Firebase
  Map<String, Map<String, dynamic>> _metalRates = {};
  Map<String, String> _metalTypes = {};

  // Shop Details - Update with your real shop details
  final shopDetails = {
    'name': "Raja's Jewelry Private Ltd.",
    'address': "New Baneshwore, Kathmandu, Nepal",
    'phone': "9803004714, 9813566214",
    'gst': "GSTIN1234567890",
    'email': "info@jewelnepal.com",
    'website': "www.jewelnepal.com",
  };

  @override
  void initState() {
    super.initState();
    // Add one empty item by default
    _items.add(
      JewelryItem(
        goldType: '22K',
        makingCharge: 0.0,
        wastagePercent: 0.0,
        weightUnit: 'Gram',
      ),
    );

    // Initialize controllers
    _makingChargeController.text = '0.0';
    _wastageController.text = '0.0';
    _advancePaymentController.text = '0.0';
    _discountController.text = '0.0';

    // Fetch metal rates from Firebase
    _fetchMetalRates();
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _goldRateController.dispose();
    _goldRateTolaController.dispose();
    _makingChargeController.dispose();
    _wastageController.dispose();
    _advancePaymentController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _fetchMetalRates() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('metals').get();

      if (!mounted) return;

      // Clear existing data first
      _metalRates = {};
      _metalTypes = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String;
        final type = data['type'] as String;

        _metalRates[name] = {
          'price': (data['price'] as num).toDouble(),
          'type': type,
        };

        _metalTypes[name] = type;
      }

      // Set default gold rate if available
      if (_metalRates.containsKey('Gold 22K')) {
        final pricePerGram = _metalRates['Gold 22K']!['price'].toDouble();
        _goldRateController.text = pricePerGram.toString();
        _goldRateTolaController.text = (pricePerGram * _gramsPerTola)
            .toStringAsFixed(2);
      } else if (_metalRates.isNotEmpty) {
        // Pick first gold item if 22K not found
        var goldItem = _metalRates.entries.firstWhere(
          (entry) => entry.value['type'] == 'Gold',
          orElse: () => _metalRates.entries.first,
        );
        final pricePerGram = goldItem.value['price'].toDouble();
        _goldRateController.text = pricePerGram.toString();
        _goldRateTolaController.text = (pricePerGram * _gramsPerTola)
            .toStringAsFixed(2);
      } else {
        // Fallback to default
        _goldRateController.text = '10500'; // Default per gram price
        _goldRateTolaController.text =
            '122457.00'; // Default per tola price (10500 * 11.6638)
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching metal rates: $e')));
      _goldRateController.text = '10500'; // Default fallback
      _goldRateTolaController.text = '122457.00'; // Default per tola price
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAndGenerateBill,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShopHeader(),
                      const SizedBox(height: 20),
                      _buildCustomerSection(),
                      const SizedBox(height: 20),
                      _buildItemsSection(isMobile),
                      const SizedBox(height: 20),
                      _buildPricingSection(isMobile),
                      const SizedBox(height: 20),
                      _buildPaymentSection(),
                      const SizedBox(height: 30),
                      _buildTotalSection(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildShopHeader() {
    return Column(
      children: [
        // Shop logo
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.diamond, color: Colors.white, size: 50),
        ),
        const SizedBox(height: 10),
        Text(
          shopDetails['name']!,
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(shopDetails['address']!, style: const TextStyle(fontSize: 14)),
        Text(
          'Tel: ${shopDetails['phone']!}',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 5),
        Text(
          'Email: ${shopDetails['email']} | ${shopDetails['website']}',
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: const Color(0xFF0D47A1).withOpacity(0.1),
          child: Center(
            child: Text(
              'INVOICE',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D47A1),
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Color(0xFF0D47A1)),
                const SizedBox(width: 8),
                Text(
                  'CUSTOMER DETAILS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D47A1),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name*',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _customerPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number*',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerAddressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(bool isMobile) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.diamond,
                      size: 18,
                      color: Color(0xFF0D47A1),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PRODUCT DETAILS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D47A1),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed:
                      () => setState(() {
                        _items.add(
                          JewelryItem(
                            goldType: '22K',
                            makingCharge: 0.0,
                            wastagePercent: 0.0,
                            weightUnit: 'Gram',
                          ),
                        );
                      }),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),

            // Headers row
            if (!isMobile)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    const SizedBox(width: 30), // Space for item number
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Item',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Weight',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Unit',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Rate',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Making',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Wastage',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Amount',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 40), // Space for delete button
                  ],
                ),
              ),

            ..._items.map((item) => _buildItemRow(item, isMobile)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(JewelryItem item, bool isMobile) {
    final index = _items.indexOf(item);

    // Create dropdown options for metals/stones
    final metalItems =
        _metalRates.keys.map((metalName) {
          return DropdownMenuItem(value: metalName, child: Text(metalName));
        }).toList();

    // Units for weight based on item type
    final weightUnits =
        item.itemType == 'Gold' || item.itemType == 'Silver'
            ? ['Gram', 'Tola']
            : ['Carat', 'Gram'];

    if (isMobile) {
      // Mobile layout - Stacked
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D47A1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (_items.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _items.removeAt(index);
                        _updateTotals();
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Item Type
            DropdownButtonFormField<String>(
              value: item.name.isNotEmpty ? item.name : null,
              items: metalItems,
              onChanged: (value) {
                setState(() {
                  item.name = value!;

                  // Set price based on selected metal
                  if (_metalRates.containsKey(value)) {
                    item.pricePerGram = _metalRates[value]!['price'];

                    // Update item type
                    if (_metalRates[value]!['type'] == 'Gold') {
                      item.itemType = 'Gold';

                      // Extract karat info if present (e.g., "Gold 22K" → "22K")
                      final nameParts = value.split(' ');
                      if (nameParts.length > 1 &&
                          nameParts.last.contains('K')) {
                        item.goldType = nameParts.last;
                      }

                      // Set default weight unit to Gram for Gold
                      if (item.weightUnit != 'Gram' &&
                          item.weightUnit != 'Tola') {
                        item.weightUnit = 'Gram';
                      }
                    } else if (_metalRates[value]!['type'] == 'Stone') {
                      item.itemType = 'Stone';

                      // Set default weight unit to Carat for Stone
                      item.weightUnit = 'Carat';
                    } else {
                      item.itemType = _metalRates[value]!['type'];

                      // Set default weight unit based on type
                      if (item.itemType == 'Silver') {
                        if (item.weightUnit != 'Gram' &&
                            item.weightUnit != 'Tola') {
                          item.weightUnit = 'Gram';
                        }
                      } else {
                        item.weightUnit = 'Gram';
                      }
                    }
                  }

                  _updateTotals();
                });
              },
              decoration: const InputDecoration(
                labelText: 'Metal/Stone Type*',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Weight and Unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: item.weight.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Weight*',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        item.weight = double.tryParse(value) ?? 0.0;
                        _updateTotals();
                      });
                    },
                    validator:
                        (value) =>
                            (value == null ||
                                    value.isEmpty ||
                                    double.tryParse(value) == 0)
                                ? 'Required'
                                : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: item.weightUnit,
                    items:
                        weightUnits
                            .map(
                              (unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (value) => setState(() {
                          item.weightUnit = value!;
                          _updateTotals();
                        }),
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Only show gold type for Gold items
            if (item.itemType == 'Gold')
              DropdownButtonFormField<String>(
                value: item.goldType,
                items:
                    ['24K', '22K', '18K', '14K']
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged:
                    (value) => setState(() {
                      item.goldType = value!;
                      _updateTotals();
                    }),
                decoration: const InputDecoration(
                  labelText: 'Gold Purity',
                  border: OutlineInputBorder(),
                ),
              ),

            if (item.itemType == 'Gold') const SizedBox(height: 16),

            // Rate per unit
            TextFormField(
              initialValue: item.pricePerGram.toString(),
              decoration: InputDecoration(
                labelText: 'Rate per ${item.weightUnit}',
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) {
                setState(() {
                  item.pricePerGram = double.tryParse(value) ?? 0.0;
                  _updateTotals();
                });
              },
            ),
            const SizedBox(height: 16),

            // Making charge and wastage
            if (item.itemType == 'Gold')
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: item.makingCharge.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Making Charge (NPR/g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          item.makingCharge = double.tryParse(value) ?? 0.0;
                          _updateTotals();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: item.wastagePercent.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Wastage (%)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          item.wastagePercent = double.tryParse(value) ?? 0.0;
                          _updateTotals();
                        });
                      },
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Item total
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Item Total:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'रू ${_calculateItemPrice(item).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Desktop/Tablet layout - Row based
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            // Item number
            SizedBox(
              width: 30,
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Item Type
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DropdownButtonFormField<String>(
                  value: item.name.isNotEmpty ? item.name : null,
                  items: metalItems,
                  onChanged: (value) {
                    setState(() {
                      item.name = value!;

                      // Same logic as mobile for item type, purity, etc.
                      if (_metalRates.containsKey(value)) {
                        item.pricePerGram = _metalRates[value]!['price'];

                        if (_metalRates[value]!['type'] == 'Gold') {
                          item.itemType = 'Gold';
                          final nameParts = value.split(' ');
                          if (nameParts.length > 1 &&
                              nameParts.last.contains('K')) {
                            item.goldType = nameParts.last;
                          }
                          if (item.weightUnit != 'Gram' &&
                              item.weightUnit != 'Tola') {
                            item.weightUnit = 'Gram';
                          }
                        } else if (_metalRates[value]!['type'] == 'Stone') {
                          item.itemType = 'Stone';
                          item.weightUnit = 'Carat';
                        } else {
                          item.itemType = _metalRates[value]!['type'];
                          if (item.itemType == 'Silver') {
                            if (item.weightUnit != 'Gram' &&
                                item.weightUnit != 'Tola') {
                              item.weightUnit = 'Gram';
                            }
                          } else {
                            item.weightUnit = 'Gram';
                          }
                        }
                      }

                      _updateTotals();
                    });
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null ? 'Required' : null,
                ),
              ),
            ),

            // Weight
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextFormField(
                  initialValue: item.weight.toString(),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      item.weight = double.tryParse(value) ?? 0.0;
                      _updateTotals();
                    });
                  },
                ),
              ),
            ),

            // Unit
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DropdownButtonFormField<String>(
                  value: item.weightUnit,
                  items:
                      weightUnits
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (value) => setState(() {
                        item.weightUnit = value!;
                        _updateTotals();
                      }),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),

            // Rate
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextFormField(
                  initialValue: item.pricePerGram.toString(),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      item.pricePerGram = double.tryParse(value) ?? 0.0;
                      _updateTotals();
                    });
                  },
                ),
              ),
            ),

            // Making charge
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextFormField(
                  initialValue: item.makingCharge.toString(),
                  enabled: item.itemType == 'Gold',
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      item.makingCharge = double.tryParse(value) ?? 0.0;
                      _updateTotals();
                    });
                  },
                ),
              ),
            ),

            // Wastage
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextFormField(
                  initialValue: item.wastagePercent.toString(),
                  enabled: item.itemType == 'Gold',
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      item.wastagePercent = double.tryParse(value) ?? 0.0;
                      _updateTotals();
                    });
                  },
                ),
              ),
            ),

            // Amount
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'रू ${_calculateItemPrice(item).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            // Delete button
            SizedBox(
              width: 40,
              child:
                  _items.length > 1
                      ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            _items.removeAt(index);
                            _updateTotals();
                          });
                        },
                      )
                      : const SizedBox(),
            ),
          ],
        ),
      );
    }
  }

  double _calculateItemPrice(JewelryItem item) {
    if (item.weight <= 0 || item.name.isEmpty) return 0;

    double effectiveWeight = item.weight;
    double pricePerUnit = item.pricePerGram;

    // Convert between weight units if necessary
    if (item.weightUnit == 'Tola') {
      // Convert tola to grams for calculation
      effectiveWeight = item.weight * _gramsPerTola;
    } else if (item.weightUnit == 'Carat' && item.itemType != 'Stone') {
      // If we have carats for non-stone items, convert to grams (just in case)
      effectiveWeight = item.weight * 0.2; // 1 carat = 0.2 grams
    }

    double basePrice;

    if (item.weightUnit == 'Tola' &&
        (item.itemType == 'Gold' || item.itemType == 'Silver')) {
      // For tola, price is already per tola
      basePrice = item.weight * pricePerUnit;
    } else if (item.weightUnit == 'Carat' && item.itemType == 'Stone') {
      // For stones, price is per carat
      basePrice = item.weight * pricePerUnit;
    } else {
      // For everything else, price is per gram
      basePrice = effectiveWeight * pricePerUnit;
    }

    // Add making charges
    double makingCharges = item.makingCharge * effectiveWeight;

    // Add wastage
    double wastage = basePrice * (item.wastagePercent / 100);

    return basePrice + makingCharges + wastage;
  }

  Widget _buildPricingSection(bool isMobile) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  size: 18,
                  color: Color(0xFF0D47A1),
                ),
                const SizedBox(width: 8),
                Text(
                  'PRICING DETAILS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D47A1),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),

            // Gold rates (per gram and per tola)
            isMobile
                ? Column(
                  children: [
                    _buildGoldRateField(isForTola: false),
                    const SizedBox(height: 16),
                    _buildGoldRateField(isForTola: true),
                  ],
                )
                : Row(
                  children: [
                    Expanded(child: _buildGoldRateField(isForTola: false)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildGoldRateField(isForTola: true)),
                  ],
                ),
            const SizedBox(height: 16),

            // Discount
            TextFormField(
              controller: _discountController,
              decoration: const InputDecoration(
                labelText: 'Discount (NPR)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) {
                setState(() {
                  _discountAmount = double.tryParse(value) ?? 0;
                  _updateTotals();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldRateField({required bool isForTola}) {
    return TextFormField(
      controller: isForTola ? _goldRateTolaController : _goldRateController,
      decoration: InputDecoration(
        labelText:
            isForTola
                ? 'Gold Rate per Tola (NPR)*'
                : 'Gold Rate per Gram (NPR)*',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.currency_rupee),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) => value!.isEmpty ? 'Required' : null,
      onChanged: (value) {
        // Update gold rates and convert between tola and gram
        final rate = double.tryParse(value) ?? 0;
        setState(() {
          if (isForTola) {
            _goldRateTolaController.text = rate.toString();
            // Update per gram rate
            if (!_goldRateController.text.contains(RegExp(r'[a-zA-Z]'))) {
              _goldRateController.text = (rate / _gramsPerTola).toStringAsFixed(
                2,
              );
            }
          } else {
            _goldRateController.text = rate.toString();
            // Update per tola rate
            if (!_goldRateTolaController.text.contains(RegExp(r'[a-zA-Z]'))) {
              _goldRateTolaController.text = (rate * _gramsPerTola)
                  .toStringAsFixed(2);
            }
          }

          // Update gold item rates
          final goldRate = double.tryParse(_goldRateController.text) ?? 0;
          for (var item in _items) {
            if (item.itemType == 'Gold') {
              item.pricePerGram = goldRate;
            }
          }
          _updateTotals();
        });
      },
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, size: 18, color: Color(0xFF0D47A1)),
                const SizedBox(width: 8),
                Text(
                  'PAYMENT DETAILS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D47A1),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: _paymentMode,
                    items:
                        _paymentModes
                            .map(
                              (mode) => DropdownMenuItem(
                                value: mode,
                                child: Text(mode),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (value) =>
                            setState(() => _paymentMode = value! as String),
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _advancePaymentController,
                    decoration: const InputDecoration(
                      labelText: 'Advance Payment (NPR)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _advancePayment = double.tryParse(value) ?? 0;
                        _updateTotals();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                Text(
                  'रू ${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GST (${(_gstRate * 100).toInt()}%):',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'रू ${_taxAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discount:', style: TextStyle(fontSize: 14)),
                Text(
                  'रू ${_discountAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Net Amount:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'रू ${_netAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Advance Payment:', style: TextStyle(fontSize: 14)),
                Text(
                  'रू ${_advancePayment.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Balance Due:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'रू ${_balanceAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _saveAndGenerateBill,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.receipt_long),
          label: const Text('Generate Invoice'),
        ),
        const SizedBox(width: 20),
        ElevatedButton.icon(
          onPressed: _clearForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.clear),
          label: const Text('Clear'),
        ),
      ],
    );
  }

  void _updateTotals() {
    double subTotal = 0.0;

    // Calculate total based on items
    for (var item in _items) {
      subTotal += _calculateItemPrice(item);
    }

    // GST calculation (13%)
    double gst = subTotal * _gstRate;

    // Net amount after discount
    double netAmount = subTotal + gst - _discountAmount;

    // Balance due after advance payment
    double balanceDue = netAmount - _advancePayment;

    setState(() {
      _totalAmount = subTotal;
      _taxAmount = gst;
      _netAmount = netAmount;
      _balanceAmount = balanceDue;
    });
  }

  void _clearForm() {
    setState(() {
      _customerNameController.clear();
      _customerPhoneController.clear();
      _customerAddressController.clear();
      _advancePaymentController.text = '0.0';
      _discountController.text = '0.0';

      _items.clear();
      _items.add(
        JewelryItem(
          goldType: '22K',
          makingCharge: 0.0,
          wastagePercent: 0.0,
          weightUnit: 'Gram',
        ),
      );

      _discountAmount = 0.0;
      _advancePayment = 0.0;

      _updateTotals();
    });
  }

  void _saveAndGenerateBill() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator
        setState(() {
          _isLoading = true;
        });

        // Create invoice object
        final invoice = Invoice(
          customerName: _customerNameController.text,
          customerPhone: _customerPhoneController.text,
          customerAddress: _customerAddressController.text,
          items:
              _items.map((item) {
                return JewelryItem(
                  name: item.name,
                  itemType: item.itemType,
                  goldType: item.goldType,
                  weight: item.weight,
                  pricePerGram: item.pricePerGram,
                  makingCharge: item.makingCharge,
                  wastagePercent: item.wastagePercent,
                  totalPrice: _calculateItemPrice(item),
                  weightUnit: item.weightUnit,
                );
              }).toList(),
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
          shopDetails: shopDetails,
          totalAmount: _totalAmount,
          taxAmount: _taxAmount,
          discountAmount: _discountAmount,
          netAmount: _netAmount,
          advancePayment: _advancePayment,
          balanceAmount: _balanceAmount,
          paymentMode: _paymentMode,
          goldRatePerGram: double.tryParse(_goldRateController.text) ?? 0.0,
          goldRatePerTola: double.tryParse(_goldRateTolaController.text) ?? 0.0,
        );

        // Save invoice to Firebase
        await FirebaseFirestore.instance
            .collection('sales')
            .doc(invoice.invoiceNumber)
            .set({
              'customerName': invoice.customerName,
              'customerPhone': invoice.customerPhone,
              'customerAddress': invoice.customerAddress,
              'invoiceNumber': invoice.invoiceNumber,
              'date': invoice.date,
              'totalAmount': invoice.totalAmount,
              'taxAmount': invoice.taxAmount,
              'discountAmount': invoice.discountAmount,
              'netAmount': invoice.netAmount,
              'advancePayment': invoice.advancePayment,
              'balanceAmount': invoice.balanceAmount,
              'paymentMode': invoice.paymentMode,
              'goldRatePerGram': invoice.goldRatePerGram,
              'goldRatePerTola': invoice.goldRatePerTola,
              'items':
                  invoice.items
                      .map(
                        (item) => {
                          'name': item.name,
                          'itemType': item.itemType,
                          'goldType': item.goldType,
                          'weight': item.weight,
                          'weightUnit': item.weightUnit,
                          'pricePerGram': item.pricePerGram,
                          'makingCharge': item.makingCharge,
                          'wastagePercent': item.wastagePercent,
                          'totalPrice': item.totalPrice,
                        },
                      )
                      .toList(),
              'timestamp': FieldValue.serverTimestamp(),
            });

        // Generate PDF using the enhanced PDF service
        final pdfFile = await JewelryPdfService.generateInvoice(invoice);

        // Hide loading indicator
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        // Show success and offer to view PDF
        _showPdfOptions(context, pdfFile, invoice.invoiceNumber);
      } catch (e) {
        // Hide loading indicator
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        // Show error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating invoice: $e')));
      }
    }
  }

  void _showPdfOptions(
    BuildContext context,
    File pdfFile,
    String invoiceNumber,
  ) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Invoice Generated'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your invoice has been generated successfully.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'What would you like to do next?',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  OpenFile.open(pdfFile.path);
                },
                icon: const Icon(Icons.visibility),
                label: const Text('View'),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Share.shareFiles([
                    pdfFile.path,
                  ], text: 'Invoice $invoiceNumber');
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _clearForm();
                },
                icon: const Icon(Icons.add),
                label: const Text('New Invoice'),
              ),
            ],
          ),
    );
  }
}
