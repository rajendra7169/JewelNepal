class JewelryItem {
  String name;
  String itemType; // Gold, Silver, Diamond, Stone, etc.
  String goldType; // 24K, 22K, 18K, etc. (only for gold items)
  double weight;
  String weightUnit; // Gram, Tola, Carat
  double pricePerGram;
  double makingCharge;
  double wastagePercent;
  double totalPrice;

  JewelryItem({
    this.name = '',
    this.itemType = 'Gold',
    required this.goldType,
    this.weight = 0.0,
    this.weightUnit = 'Gram',
    this.pricePerGram = 0.0,
    required this.makingCharge,
    required this.wastagePercent,
    this.totalPrice = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'itemType': itemType,
      'goldType': goldType,
      'weight': weight,
      'weightUnit': weightUnit,
      'pricePerGram': pricePerGram,
      'makingCharge': makingCharge,
      'wastagePercent': wastagePercent,
      'totalPrice': totalPrice,
    };
  }
}
