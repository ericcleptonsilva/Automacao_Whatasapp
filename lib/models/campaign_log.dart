import 'contact.dart';

class CampaignLog {
  final String id;
  final String message;
  final List<Contact> contacts;
  final DateTime timestamp;

  CampaignLog({
    required this.id,
    required this.message,
    required this.contacts,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'contacts': contacts.map((c) => c.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CampaignLog.fromJson(Map<String, dynamic> json) {
    return CampaignLog(
      id: json['id'] as String,
      message: json['message'] as String,
      contacts: (json['contacts'] as List)
          .map((c) => Contact.fromJson(c as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
