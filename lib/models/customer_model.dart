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
}

class Customer {
  final String id;
  final String name;
  final List<String> phoneNumbers;
  final String? email;
  final String? panNumber;
  final Address? address;
  final String? photoUrl;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.phoneNumbers,
    this.email,
    this.panNumber,
    this.address,
    this.photoUrl,
    required this.createdAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    List<String>? phoneNumbers,
    String? email,
    String? panNumber,
    Address? address,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      email: email ?? this.email,
      panNumber: panNumber ?? this.panNumber,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
