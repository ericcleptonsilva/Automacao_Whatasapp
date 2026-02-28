import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';

class ContactRepository {
  static const String _keyContacts = 'contacts';

  Future<void> saveContact(Contact contact) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> contactsJson = prefs.getStringList(_keyContacts) ?? [];
    
    // Check if exists and update, or add new
    final existingIndex = contactsJson.indexWhere((c) {
      final decoded = jsonDecode(c);
      return decoded['id'] == contact.id;
    });

    if (existingIndex >= 0) {
      contactsJson[existingIndex] = jsonEncode(contact.toJson());
    } else {
      contactsJson.add(jsonEncode(contact.toJson()));
    }

    await prefs.setStringList(_keyContacts, contactsJson);
  }

  Future<List<Contact>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> contactsJson = prefs.getStringList(_keyContacts) ?? [];
    
    return contactsJson
        .map((c) => Contact.fromJson(jsonDecode(c)))
        .toList();
  }

  Future<void> deleteContact(String id) async {
    await deleteContacts([id]);
  }

  Future<void> deleteContacts(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> contactsJson = prefs.getStringList(_keyContacts) ?? [];
    
    contactsJson.removeWhere((c) {
      final decoded = jsonDecode(c);
      return ids.contains(decoded['id']);
    });

    await prefs.setStringList(_keyContacts, contactsJson);
  }
}
