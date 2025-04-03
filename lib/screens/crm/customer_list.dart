import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../services/crm_service.dart';
import '../../widgets/customer_avatar.dart'; // Ensure this file defines the CustomerAvatar widget

// If the CustomerAvatar widget is not defined, define it here or in the appropriate file.
import 'add_edit_customer_screen.dart';
import 'package:provider/provider.dart';

import '../models/customer_model.dart';

class CrmService {
  Future<List<Customer>> getCustomers() async {
    // Mock implementation
    return [];
  }

  List<Customer> searchCustomers(String query) {
    // Mock implementation
    return [];
  }
}

class CustomerSearchDelegate extends SearchDelegate<Customer?> {
  final CrmService crmService;

  CustomerSearchDelegate(this.crmService);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = crmService.searchCustomers(query);
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final customer = results[index];
        return ListTile(
          title: Text(customer.name),
          subtitle: Text(customer.phoneNumbers.join(', ')),
          onTap: () {
            close(context, customer);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = crmService.searchCustomers(query);
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final customer = suggestions[index];
        return ListTile(
          title: Text(customer.name),
          onTap: () {
            query = customer.name;
            showResults(context);
          },
        );
      },
    );
  }
}

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed:
                () => showSearch(
                  context: context,
                  delegate: CustomerSearchDelegate(
                    Provider.of<CrmService>(context, listen: false),
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEditCustomerScreen(),
              ),
            ),
        child: const Icon(Icons.add),
      ),
      body: Consumer<CrmService>(
        builder: (context, crmService, child) {
          return FutureBuilder<List<Customer>>(
            future: crmService.getCustomers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading customers: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No customers found.\nAdd customers using the + button.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final customers = snapshot.data!;
              return ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  return CustomerListItem(customer: customers[index]);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class CustomerListItem extends StatelessWidget {
  final Customer customer;

  const CustomerListItem({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CustomerAvatar(
          photoUrl: customer.photoUrl,
          name: customer.name,
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.phoneNumbers.isNotEmpty)
              Text(customer.phoneNumbers.join(', ')),
            if (customer.address != null &&
                customer.address!.district.isNotEmpty &&
                customer.address!.province.isNotEmpty)
              Text(
                '${customer.address!.district}, ${customer.address!.province}',
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditCustomerScreen(customer: customer),
              ),
            ),
      ),
    );
  }
}

class CustomerAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;

  const CustomerAvatar({Key? key, this.photoUrl, required this.name})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      child: photoUrl == null ? Text(name[0].toUpperCase()) : null,
    );
  }
}
