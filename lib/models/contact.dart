class Contact {
  final String id;
  final String name;
  final String phone;
  final List<String> tags;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'tags': tags,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}
