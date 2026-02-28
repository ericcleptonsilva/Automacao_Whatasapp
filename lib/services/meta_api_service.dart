import 'dart:convert';
import 'package:http/http.dart' as http;
import '../repositories/meta_api_repository.dart';
import 'logger_service.dart';

class MetaApiService {
  final MetaApiRepository _repository = MetaApiRepository();

  Future<bool> sendMessage({
    required String to,
    required String message,
  }) async {
    final creds = await _repository.getCredentials();
    final token = creds['accessToken'];
    final phoneId = creds['phoneId'];

    if (token == null || phoneId == null) {
      LoggerService.log('Meta API Credentials missing');
      return false;
    }

    final url = Uri.parse('https://graph.facebook.com/v18.0/$phoneId/messages');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "messaging_product": "whatsapp",
          "recipient_type": "individual",
          "to": to,
          "type": "text",
          "text": {
            "preview_url": false,
            "body": message
          }
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        LoggerService.log('Meta API Error: ${response.body}');
        return false;
      }
    } catch (e) {
      LoggerService.log('Meta API Exception: $e');
      return false;
    }
  }
}
