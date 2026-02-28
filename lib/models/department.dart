class Department {
  final String id;
  final String name;
  final String phoneNumber;
  final String description;

  Department({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'description': description,
    };
  }

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
