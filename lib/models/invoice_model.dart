import 'jewelry_item.dart';

class Invoice {
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final List<JewelryItem> items;
  final String date;
  final String invoiceNumber;
  final Map<String, String> shopDetails;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final double netAmount;
  final double advancePayment;
  final double balanceAmount;
  final String paymentMode;
  final double goldRatePerGram;
  final double goldRatePerTola;

  Invoice({
    required this.customerName,
    required this.customerPhone,
    this.customerAddress = '',
    required this.items,
    required this.date,
    required this.invoiceNumber,
    required this.shopDetails,
    required this.totalAmount,
    required this.taxAmount,
    this.discountAmount = 0.0,
    required this.netAmount,
    this.advancePayment = 0.0,
    required this.balanceAmount,
    this.paymentMode = 'Cash',
    this.goldRatePerGram = 0.0,
    this.goldRatePerTola = 0.0,
  });
}
