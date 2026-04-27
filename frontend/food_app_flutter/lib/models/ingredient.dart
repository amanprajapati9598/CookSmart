class Ingredient {
  final int id;
  final String name;

  Ingredient({required this.id, required this.name});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: int.tryParse(json['Ingredient_ID'].toString()) ?? DateTime.now().millisecondsSinceEpoch,
      name: json['Name'] ?? 'Unknown',
    );
  }
}
