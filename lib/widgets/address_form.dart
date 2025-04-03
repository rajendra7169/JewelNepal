import 'package:flutter/material.dart';
import '../models/customer_model.dart';

class Address {
  final String province;
  final String district;
  final String municipality;
  final int ward;
  final String streetAddress;

  Address({
    required this.province,
    required this.district,
    required this.municipality,
    required this.ward,
    required this.streetAddress,
  });

  Address copyWith({
    String? province,
    String? district,
    String? municipality,
    int? ward,
    String? streetAddress,
  }) {
    return Address(
      province: province ?? this.province,
      district: district ?? this.district,
      municipality: municipality ?? this.municipality,
      ward: ward ?? this.ward,
      streetAddress: streetAddress ?? this.streetAddress,
    );
  }
}

class AddressForm extends StatefulWidget {
  final Address initialAddress;
  final Function(Address) onAddressChanged;

  const AddressForm({
    super.key,
    required this.initialAddress,
    required this.onAddressChanged,
  });

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  late Address _address;

  @override
  void initState() {
    _address = widget.initialAddress;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Address Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        DropdownButtonFormField<String>(
          value: _address.province,
          items:
              provinces
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
          onChanged:
              (value) => setState(() {
                _address = _address.copyWith(province: value!);
                widget.onAddressChanged(_address);
              }),
          decoration: const InputDecoration(labelText: 'Province*'),
        ),
        DropdownButtonFormField<String>(
          value: _address.district,
          items:
              districts
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
          onChanged:
              (value) => setState(() {
                _address = _address.copyWith(district: value!);
                widget.onAddressChanged(_address);
              }),
          decoration: const InputDecoration(labelText: 'District*'),
        ),
        DropdownButtonFormField<String>(
          value: _address.municipality,
          items:
              municipalities
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
          onChanged:
              (value) => setState(() {
                _address = _address.copyWith(municipality: value!);
                widget.onAddressChanged(_address);
              }),
          decoration: const InputDecoration(labelText: 'Municipality*'),
        ),
        DropdownButtonFormField<int>(
          value: _address.ward,
          items: List.generate(
            35,
            (index) => DropdownMenuItem(
              value: index + 1,
              child: Text('Ward ${index + 1}'),
            ),
          ),
          onChanged:
              (value) => setState(() {
                _address = _address.copyWith(ward: value!);
                widget.onAddressChanged(_address);
              }),
          decoration: const InputDecoration(labelText: 'Ward*'),
        ),
        TextFormField(
          initialValue: _address.streetAddress,
          decoration: const InputDecoration(labelText: 'Street Address'),
          onChanged:
              (value) => _address = _address.copyWith(streetAddress: value),
        ),
      ],
    );
  }
}

// Sample lists - replace with actual Nepal data
const List<String> provinces = [
  'Province 1',
  'Madhesh',
  'Bagmati',
  'Gandaki',
  'Lumbini',
  'Karnali',
  'Sudurpashchim',
];

const List<String> districts = [
  'District 1',
  'District 2',
  'District 3',
  'District 4',
  'District 5',
];

const List<String> municipalities = [
  'Municipality 1',
  'Municipality 2',
  'Municipality 3',
  'Municipality 4',
  'Municipality 5',
];
