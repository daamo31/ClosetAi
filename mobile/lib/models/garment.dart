/// models/garment.dart — Modelo de prenda
library;

class Garment {
  final String  id;
  final String  userId;
  final String  name;
  final String  category;
  final String  color;
  final String  season;
  final String  occasion;
  final double  purchasePrice;
  final String? imageUrl;
  final int     timesUsed;
  final double  costPerWear;
  final DateTime createdAt;

  const Garment({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.color,
    required this.season,
    required this.occasion,
    required this.purchasePrice,
    this.imageUrl,
    required this.timesUsed,
    required this.costPerWear,
    required this.createdAt,
  });

  factory Garment.fromJson(Map<String, dynamic> json) => Garment(
        id:            json['id'] as String,
        userId:        json['user_id'] as String,
        name:          json['name'] as String,
        category:      json['category'] as String,
        color:         json['color'] as String,
        season:        json['season'] as String,
        occasion:      json['occasion'] as String,
        purchasePrice: (json['purchase_price'] as num).toDouble(),
        imageUrl:      json['image_url'] as String?,
        timesUsed:     json['times_used'] as int,
        costPerWear:   (json['cost_per_wear'] as num).toDouble(),
        createdAt:     DateTime.parse(json['created_at'] as String),
      );

  // Etiqueta de categoría en español
  String get categoryLabel => switch (category) {
        'top'       => 'Parte superior',
        'bottom'    => 'Parte inferior',
        'shoes'     => 'Calzado',
        'outerwear' => 'Ropa exterior',
        'accessory' => 'Accesorio',
        _           => category,
      };

  // Emoji según categoría
  String get categoryEmoji => switch (category) {
        'top'       => '👕',
        'bottom'    => '👖',
        'shoes'     => '👟',
        'outerwear' => '🧥',
        'accessory' => '💍',
        _           => '👗',
      };

  // Formato del CPW (ej: "3.75€")
  String get cpwFormatted =>
      timesUsed == 0 ? 'Sin usar' : '${costPerWear.toStringAsFixed(2)}€';

  // Si el CPW es bueno (< 5€ por uso = buena rentabilidad)
  bool get isGoodCpw => timesUsed > 0 && costPerWear < 5.0;

  @override
  String toString() => 'Garment($name, $category, CPW=$cpwFormatted)';
}
