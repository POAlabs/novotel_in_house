/// Floor data model
/// Represents a physical floor in the hotel with its areas
class FloorModel {
  final String id;
  final String name;
  final List<String> areas;

  const FloorModel({
    required this.id,
    required this.name,
    required this.areas,
  });

  /// Factory constructor for JSON deserialization
  factory FloorModel.fromJson(Map<String, dynamic> json) {
    return FloorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      areas: List<String>.from(json['areas'] as List),
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'areas': areas,
    };
  }
}
