import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jewelry_app/screens/crm/customer_list.dart';
import 'package:provider/provider.dart';
import '../../models/customer_model.dart' as customer_model;
import '../../services/crm_service.dart';
import '../../widgets/address_form.dart' as address_form;

// Add this TextInputFormatter for PAN number
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class Address {
  final String province;
  final String district; // Added district property
  final String municipality;
  final int ward;
  final String streetAddress;

  Address({
    required this.province,
    required this.district, // Initialize district
    required this.municipality,
    required this.ward,
    required this.streetAddress,
  });
}

class ImagePickerWidget extends StatelessWidget {
  final String? initialImage;
  final Function(XFile) onImagePicked;

  const ImagePickerWidget({
    Key? key,
    this.initialImage,
    required this.onImagePicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (initialImage != null)
          Image.network(
            initialImage!,
            height: 150,
            width: 150,
            fit: BoxFit.cover,
          )
        else
          Container(
            height: 150,
            width: 150,
            color: Colors.grey.shade300,
            child: Icon(Icons.person, size: 80, color: Colors.grey.shade600),
          ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(
              source: ImageSource.gallery,
            );
            if (pickedFile != null) {
              onImagePicked(pickedFile);
            }
          },
          child: const Text('Select Photo'),
        ),
      ],
    );
  }
}

class PhoneNumberFields extends StatefulWidget {
  final List<String> initialNumbers;
  final ValueChanged<List<String>> onChanged;

  const PhoneNumberFields({
    Key? key,
    required this.initialNumbers,
    required this.onChanged,
  }) : super(key: key);

  @override
  _PhoneNumberFieldsState createState() => _PhoneNumberFieldsState();
}

class _PhoneNumberFieldsState extends State<PhoneNumberFields> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers =
        widget.initialNumbers
            .map((number) => TextEditingController(text: number))
            .toList();

    // If empty, add at least one controller
    if (_controllers.isEmpty) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPhoneNumberField() {
    setState(() {
      _controllers.add(TextEditingController());
    });
    _updatePhoneNumbers();
  }

  void _removePhoneNumberField(int index) {
    setState(() {
      _controllers.removeAt(index);
      // Always keep at least one phone number field
      if (_controllers.isEmpty) {
        _controllers.add(TextEditingController());
      }
    });
    _updatePhoneNumbers();
  }

  void _updatePhoneNumbers() {
    final numbers = _controllers.map((c) => c.text).toList();
    widget.onChanged(numbers);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._controllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Phone Number ${index + 1}',
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => _updatePhoneNumbers(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  onPressed:
                      _controllers.length > 1
                          ? () => _removePhoneNumberField(index)
                          : null,
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: _addPhoneNumberField,
          icon: const Icon(Icons.add),
          label: const Text('Add Phone Number'),
        ),
      ],
    );
  }
}

class AddressForm extends StatefulWidget {
  final address_form.Address initialAddress;
  final ValueChanged<address_form.Address> onAddressChanged;

  const AddressForm({
    Key? key,
    required this.initialAddress,
    required this.onAddressChanged,
  }) : super(key: key);

  @override
  _AddressFormState createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  late TextEditingController _provinceController;
  late TextEditingController _districtController;
  late TextEditingController _municipalityController;
  late TextEditingController _wardController;
  late TextEditingController _streetController;

  @override
  void initState() {
    super.initState();
    _provinceController = TextEditingController(
      text: widget.initialAddress.province,
    );
    _districtController = TextEditingController(
      text: widget.initialAddress.district,
    );
    _municipalityController = TextEditingController(
      text: widget.initialAddress.municipality,
    );
    _wardController = TextEditingController(
      text: widget.initialAddress.ward.toString(),
    );
    _streetController = TextEditingController(
      text: widget.initialAddress.streetAddress,
    );

    // Set up listeners for all controllers
    _provinceController.addListener(_updateAddress);
    _districtController.addListener(_updateAddress);
    _municipalityController.addListener(_updateAddress);
    _wardController.addListener(_updateAddress);
    _streetController.addListener(_updateAddress);
  }

  @override
  void dispose() {
    _provinceController.dispose();
    _districtController.dispose();
    _municipalityController.dispose();
    _wardController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  void _updateAddress() {
    final ward = int.tryParse(_wardController.text) ?? 0;
    widget.onAddressChanged(
      address_form.Address(
        province: _provinceController.text,
        district: _districtController.text,
        municipality: _municipalityController.text,
        ward: ward,
        streetAddress: _streetController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Address Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _provinceController,
          decoration: const InputDecoration(labelText: 'Province'),
        ),
        TextFormField(
          controller: _districtController,
          decoration: const InputDecoration(labelText: 'District'),
        ),
        TextFormField(
          controller: _municipalityController,
          decoration: const InputDecoration(labelText: 'Municipality/VDC'),
        ),
        TextFormField(
          controller: _wardController,
          decoration: const InputDecoration(labelText: 'Ward'),
          keyboardType: TextInputType.number,
        ),
        TextFormField(
          controller: _streetController,
          decoration: const InputDecoration(labelText: 'Street Address'),
        ),
      ],
    );
  }
}

class AddEditCustomerScreen extends StatefulWidget {
  final customer_model.Customer? customer;

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  List<String> _phoneNumbers = [];
  XFile? _imageFile;
  address_form.Address _address = address_form.Address(
    province: '',
    district: '',
    municipality: '',
    ward: 0,
    streetAddress: '',
  );

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _emailController.text = widget.customer!.email ?? '';
      _panController.text = widget.customer!.panNumber ?? '';
      _phoneNumbers = List<String>.from(widget.customer!.phoneNumbers);
      if (widget.customer!.address != null) {
        // Convert from Customer.Address to address_form.Address
        _address = address_form.Address(
          province: widget.customer!.address!.province,
          district: widget.customer!.address!.district,
          municipality: widget.customer!.address!.municipality,
          ward: widget.customer!.address!.ward,
          streetAddress: widget.customer!.address!.streetAddress,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _panController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'New Customer' : 'Edit Customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ImagePickerWidget(
                initialImage: widget.customer?.photoUrl,
                onImagePicked: (file) => setState(() => _imageFile = file),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name*'),
                validator:
                    (value) =>
                        value != null && value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              PhoneNumberFields(
                initialNumbers: _phoneNumbers,
                onChanged: (numbers) => _phoneNumbers = numbers,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _panController,
                decoration: const InputDecoration(labelText: 'PAN Number'),
                inputFormatters: [UpperCaseTextFormatter()],
              ),
              const SizedBox(height: 20),
              AddressForm(
                initialAddress: _address,
                onAddressChanged: (address) => _address = address,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Save Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final customerAddress = customer_model.Address(
          province: _address.province,
          district: _address.district,
          municipality: _address.municipality,
          ward: _address.ward,
          streetAddress: _address.streetAddress,
        );

        final customer = customer_model.Customer(
          id: widget.customer?.id ?? DateTime.now().toString(),
          name: _nameController.text,
          phoneNumbers:
              _phoneNumbers.where((phone) => phone.isNotEmpty).toList(),
          email: _emailController.text.isEmpty ? null : _emailController.text,
          panNumber: _panController.text.isEmpty ? null : _panController.text,
          address: customerAddress,
          photoUrl: widget.customer?.photoUrl,
          createdAt: widget.customer?.createdAt ?? DateTime.now(),
        );

        final crmService = Provider.of<CrmService>(context, listen: false);

        if (_imageFile != null) {
          // Upload image logic would go here
          // This is a simple placeholder:
          print('Would upload image: ${_imageFile!.path}');
          // final photoUrl = await crmService.uploadCustomerImage(_imageFile!);
          // final updatedCustomer = customer.copyWith(photoUrl: photoUrl);
          // await crmService.updateCustomer(updatedCustomer);
        }

        if (widget.customer == null) {
          await crmService.addCustomer(customer);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Customer added successfully')),
            );
          }
        } else {
          await crmService.updateCustomer(customer);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Customer updated successfully')),
            );
          }
        }

        if (mounted) Navigator.pop(context);
      } catch (e) {
        print('Error saving customer: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

class CrmService {
  // Existing methods and properties

  Future<void> updateCustomer(customer_model.Customer customer) async {
    // Add logic to update the customer in the database or API
    // Example:
    // await database.update('customers', customer.toMap());
  }

  Future<void> addCustomer(customer_model.Customer customer) async {
    // Add logic to add the customer to the database or API
    // Example:
    // await database.insert('customers', customer.toMap());
  }
}
