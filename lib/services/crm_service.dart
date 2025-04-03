import 'package:flutter/material.dart';
import '../models/customer_model.dart';

class CrmService extends ChangeNotifier {
  List<Customer> _customers = [];

  Future<List<Customer>> getCustomers() async {
    // In a real app, you'd fetch from a database or API
    // For now, just return the in-memory list
    return _customers;
  }

  Future<void> addCustomer(Customer customer) async {
    _customers.add(customer);
    notifyListeners();
    // In a real app, you'd save to a database or API
  }

  Future<void> updateCustomer(Customer customer) async {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) {
      _customers[index] = customer;
      notifyListeners();
    }
    // In a real app, you'd update in a database or API
  }

  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return _customers;
    final lowercaseQuery = query.toLowerCase();
    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(lowercaseQuery) ||
          customer.phoneNumbers.any((phone) => phone.contains(query));
    }).toList();
  }
}
