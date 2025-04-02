import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';

class JewelryPdfService {
  static Future<File> generateInvoice(Invoice invoice) async {
    final pdf = pw.Document();
    
    // Load logo image if available
    pw.MemoryImage? logoImage;
    try {
      final byteData = await rootBundle.load('assets/logo.png');
      final bytes = byteData.buffer.asUint8List();
      logoImage = pw.MemoryImage(bytes);
    } catch (e) {
      // Logo loading failed, will use text instead
    }
    
    // Add styles
    final titleStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 20,
      color: PdfColors.indigo900,
    );
    
    final headerStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 15,
      color: PdfColors.indigo900,
    );
    
    final subheaderStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 12,
      color: PdfColors.indigo800,
    );
    
    final normalBoldStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 11,
    );
    
    final smallStyle = pw.TextStyle(
      fontSize: 10,
      color: PdfColors.grey700,
    );

    // Build PDF document
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              // Shop Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo
                  logoImage != null
                      ? pw.Container(
                          width: 70,
                          height: 70,
                          child: pw.Image(logoImage),
                        )
                      : pw.Container(
                          width: 70,
                          height: 70,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.indigo900,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              'JN',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                  pw.SizedBox(width: 15),
                  
                  // Shop info
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(invoice.shopDetails['name']!, style: titleStyle),
                        pw.SizedBox(height: 5),
                        pw.Text(invoice.shopDetails['address']!, style: pw.TextStyle(fontSize: 12)),
                        pw.Text('Phone: ${invoice.shopDetails['phone']!}', style: pw.TextStyle(fontSize: 12)),
                        if (invoice.shopDetails['email'] != null)
                          pw.Text('Email: ${invoice.shopDetails['email']} | ${invoice.shopDetails['website'] ?? ''}', 
                            style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  
                  // Invoice details
                  pw.Container(
                    width: 160,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.indigo50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColors.indigo200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('INVOICE', style: headerStyle),
                        pw.Divider(color: PdfColors.indigo200),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Invoice No:', style: normalBoldStyle),
                            pw.Text(invoice.invoiceNumber.split('-').last, style: normalBoldStyle),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Date:', style: normalBoldStyle),
                            pw.Text(invoice.date, style: normalBoldStyle),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Gold rate display
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.amber300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    pw.Text(
                      'Gold Rate: रू ${NumberFormat('#,##0.00').format(invoice.goldRatePerGram ?? 0.0)}/g',
                      style: normalBoldStyle,
                    ),
                    pw.Container(height: 20, width: 1, color: PdfColors.amber700),
                    pw.Text(
                      'रू ${NumberFormat('#,##0.00').format((invoice.goldRatePerGram ?? 0.0) * 11.6638)}/tola',
                      style: normalBoldStyle,
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
            ],
          );
        },
        
        build: (pw.Context context) {
          return [
            // Customer details
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BILL TO', style: subheaderStyle),
                  pw.SizedBox(height: 8),
                  pw.Text('Name: ${invoice.customerName}', style: normalBoldStyle),
                  pw.Text('Phone: ${invoice.customerPhone}', style: normalBoldStyle),
                  if (invoice.customerAddress.isNotEmpty)
                    pw.Text('Address: ${invoice.customerAddress}', style: normalBoldStyle),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Items table
            pw.Text('JEWELRY ITEMS', style: headerStyle),
            pw.SizedBox(height: 5),
            _buildItemsTable(invoice),
            
            pw.SizedBox(height: 20),
            
            // Totals
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Payment details
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PAYMENT DETAILS', style: subheaderStyle),
                        pw.SizedBox(height: 5),
                        pw.Text('Payment Mode: ${invoice.paymentMode}', style: normalBoldStyle),
                        if (invoice.advancePayment > 0)
                          pw.Text('Advance Payment: रू ${NumberFormat('#,##0.00').format(invoice.advancePayment)}', 
                            style: normalBoldStyle),
                        pw.SizedBox(height: 5),
                        pw.Text('Payment Status: ${invoice.balanceAmount > 0 ? "PARTIALLY PAID" : "FULLY PAID"}', 
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: invoice.balanceAmount > 0 ? PdfColors.orange : PdfColors.green700,
                          )),
                      ],
                    ),
                  ),
                ),
                
                pw.SizedBox(width: 20),
                
                // Bill summary
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILL SUMMARY', style: subheaderStyle),
                        pw.SizedBox(height: 8),
                        _buildTotalRow('Subtotal', invoice.totalAmount),
                        _buildTotalRow('GST (13%)', invoice.taxAmount),
                        if (invoice.discountAmount > 0)
                          _buildTotalRow('Discount', invoice.discountAmount),
                        pw.Divider(color: PdfColors.grey400),
                        _buildTotalRow('Net Amount', invoice.netAmount, isLarge: true),
                        if (invoice.advancePayment > 0)
                          _buildTotalRow('Advance Paid', invoice.advancePayment),
                        if (invoice.balanceAmount > 0) pw.Divider(color: PdfColors.grey400),
                        if (invoice.balanceAmount > 0)
                          _buildTotalRow('Balance Due', invoice.balanceAmount, isLarge: true, isRed: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 30),
            
            // Terms and conditions
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Terms & Conditions', style: subheaderStyle),
                  pw.SizedBox(height: 5),
                  pw.Text('1. Items once sold will not be taken back or exchanged.', style: smallStyle),
                  pw.Text('2. Any damage due to improper handling will not be covered under warranty.', style: smallStyle),
                  pw.Text('3. Warranty does not cover natural wear and tear.', style: smallStyle),
                  pw.Text('4. Original invoice must be presented for any warranty claim.', style: smallStyle),
                  pw.Text('5. Price is subject to change as per market fluctuations.', style: smallStyle),
                ],
              ),
            ),
            
            pw.SizedBox(height: 40),
            
            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(
                      width: 150,
                      height: 0.5,
                      color: PdfColors.black,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('Customer Signature'),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(
                      width: 150,
                      height: 0.5,
                      color: PdfColors.black,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('Authorized Signature'),
                  ],
                ),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Thank you note
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Thank you for your business!', style: subheaderStyle),
                  pw.SizedBox(height: 5),
                  pw.Text('Visit us again soon.', style: smallStyle),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // Save PDF to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Table _buildItemsTable(Invoice invoice) {
    final headers = [
      'Item',
      'Type',
      'Weight',
      'Unit',
      'Rate',
      'Making',
      'Wastage',
      'Amount'
    ];
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),  // Item name
        1: const pw.FlexColumnWidth(2),  // Type
        2: const pw.FlexColumnWidth(1),  // Weight
        3: const pw.FlexColumnWidth(1),  // Unit
        4: const pw.FlexColumnWidth(1.5),  // Rate
        5: const pw.FlexColumnWidth(1.5),  // Making
        6: const pw.FlexColumnWidth(1),  // Wastage
        7: const pw.FlexColumnWidth(2),  // Amount
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
          children: headers.map((header) => 
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                header, 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: header == 'Amount' ? pw.TextAlign.right : pw.TextAlign.left,
              ),
            )
          ).toList(),
        ),
        
        // Item rows
        ...invoice.items.map((item) {
          final currencyFormat = NumberFormat('#,##0.00');
          
          // Determine unit and convert if needed
          String weightUnit = 'g';
          double displayWeight = item.weight;
          double displayRate = item.pricePerGram;
          
          // For gold items, show in tola if weight is higher
          if (item.itemType == 'Gold' && item.weight >= 10) {
            weightUnit = 'tola';
            displayWeight = item.weight / 11.6638;
            displayRate = item.pricePerGram * 11.6638;
          }
          
          // For stones, use carat
          if (item.itemType == 'Diamond' || item.itemType == 'Stone') {
            weightUnit = 'ct';
          }
          
          // Build item details
          String typeDisplay = item.itemType;
          if (item.itemType == 'Gold') {
            typeDisplay += ' ${item.goldType}';
          }
          
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(item.name),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(typeDisplay),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(displayWeight.toStringAsFixed(2)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(weightUnit),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('रू${currencyFormat.format(displayRate)}'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('रू${currencyFormat.format(item.makingCharge)}'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('${item.wastagePercent}%'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  'रू${currencyFormat.format(item.totalPrice)}',
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, {bool isLarge = false, bool isRed = false}) {
    final currencyFormat = NumberFormat('#,##0.00');
    
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isLarge ? pw.FontWeight.bold : null,
              fontSize: isLarge ? 12 : 10,
            ),
          ),
          pw.Text(
            'रू${currencyFormat.format(amount)}',
            style: pw.TextStyle(
              fontWeight: isLarge ? pw.FontWeight.bold : null,
              fontSize: isLarge ? 12 : 10,
              color: isRed ? PdfColors.red : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
