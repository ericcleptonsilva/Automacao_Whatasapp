import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'logger_service.dart';

abstract class AIProvider {
  final String apiKey;
  final String model;
  final String prompt;

  AIProvider({required this.apiKey, required this.model, required this.prompt});

  Future<String?> generateReply(String userMessage, {List<Map<String, String>> history = const []});
}

class GeminiProvider extends AIProvider {
  GeminiProvider({required super.apiKey, required super.model, required super.prompt});

  @override
  Future<String?> generateReply(String userMessage, {List<Map<String, String>> history = const []}) async {
    try {
      final List<Content> chatHistory = history.map((entry) {
        final role = entry['role'] == 'user' ? 'user' : 'model';
        return Content(role, [TextPart(entry['message'] ?? '')]);
      }).toList();

      final systemInstruction = Content.system(prompt);
      
      try {
        final genModel = GenerativeModel(
            model: model,
            apiKey: apiKey,
            systemInstruction: systemInstruction,
        );
        
        final chat = genModel.startChat(history: chatHistory);
        final response = await chat.sendMessage(Content.text(userMessage))
            .timeout(const Duration(seconds: 30));
        return response.text;
      } on TimeoutException catch (_) {
          LoggerService.log("GeminiProvider: Timeout after 30s using $model");
          return "Erro: Tempo esgotado (Timeout). Verifique sua conexão.";
      } catch (e) {
          final errStr = e.toString().toLowerCase();
          if (errStr.contains("429") || errStr.contains("quota") || errStr.contains("too many requests")) {
            LoggerService.log("GeminiProvider: Rate limit (429) detected.");
            return "Erro 429: Limite de uso atingido no Gemini Grátis. Aguarde um minuto e tente de novo.";
          }
          if (errStr.contains("403") || errStr.contains("api key")) {
            return "Erro 403: Chave de API inválida ou sem permissão.";
          }
          LoggerService.log("GeminiProvider: $model failed with error: $e");
          return "Erro na I.A.: $e";
      }
    } catch (e) {
      LoggerService.log("GeminiProvider Error: $e");
      return "Erro Crítico: $e";
    }
  }
}



class ClaudeProvider extends AIProvider {
  ClaudeProvider({required super.apiKey, required super.model, required super.prompt});

  @override
  Future<String?> generateReply(String userMessage, {List<Map<String, String>> history = const []}) async {
    try {
      final url = Uri.parse('https://api.anthropic.com/v1/messages');
      
      final List<Map<String, String>> messages = [
        ...history.map((e) => {
            'role': (e['role'] == 'model' || e['role'] == 'assistant') ? 'assistant' : 'user', 
            'content': e['message'] ?? ''
        }),
        {'role': 'user', 'content': userMessage}
      ];

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': model.isEmpty ? 'claude-3-haiku-20240307' : model,
          'max_tokens': 1024,
          'system': prompt,
          'messages': messages,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['content'][0]['text'];
      } else {
        LoggerService.log("Claude Error: ${response.statusCode} - ${response.body}");
        if (response.statusCode == 429) return "Erro 429: Limite de uso atingido no Claude.";
        return "Erro Claude (${response.statusCode}): ${response.body}";
      }
    } on TimeoutException {
      LoggerService.log("Claude Error: Timeout after 30s");
      return "Erro: Tempo esgotado (Timeout) no Claude.";
    } catch (e) {
      LoggerService.log("Claude Provider Error: $e");
      return "Erro Claude: $e";
    }
  }
}

class DeepSeekProvider extends AIProvider {
  DeepSeekProvider({required super.apiKey, required super.model, required super.prompt});

  @override
  Future<String?> generateReply(String userMessage, {List<Map<String, String>> history = const []}) async {
    try {
      final url = Uri.parse('https://api.deepseek.com/chat/completions');
      
      final List<Map<String, String>> messages = [
        {'role': 'system', 'content': prompt},
        ...history.map((e) => {'role': (e['role'] == 'model' || e['role'] == 'assistant') ? 'assistant' : 'user', 'content': e['message'] ?? ''}),
        {'role': 'user', 'content': userMessage}
      ];

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model.isEmpty ? 'deepseek-chat' : model,
          'messages': messages,
          'stream': false
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        LoggerService.log("DeepSeek Error: ${response.statusCode} - ${response.body}");
        if (response.statusCode == 429) return "Erro 429: Limite de uso atingido no DeepSeek.";
        return "Erro DeepSeek (${response.statusCode}): ${response.body}";
      }
    } on TimeoutException {
      LoggerService.log("DeepSeek Error: Timeout after 30s");
      return "Erro: Tempo esgotado (Timeout) no DeepSeek.";
    } catch (e) {
      LoggerService.log("DeepSeek Provider Error: $e");
      return "Erro DeepSeek: $e";
    }
  }
}

class GroqProvider extends AIProvider {
  GroqProvider({required super.apiKey, required super.model, required super.prompt});

  @override
  Future<String?> generateReply(String userMessage, {List<Map<String, String>> history = const []}) async {
    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      final List<Map<String, String>> messages = [
        {'role': 'system', 'content': prompt},
        ...history.map((e) => {'role': (e['role'] == 'model' || e['role'] == 'assistant') ? 'assistant' : 'user', 'content': e['message'] ?? ''}),
        {'role': 'user', 'content': userMessage}
      ];

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model.isEmpty ? 'llama-3.1-8b-instant' : model,
          'messages': messages,
          'stream': false
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        LoggerService.log("Groq Error: ${response.statusCode} - ${response.body}");
        if (response.statusCode == 429) return "Erro 429: Limite de requisições excedido no Groq.";
        return "Erro Groq (${response.statusCode}): ${response.body}";
      }
    } on TimeoutException {
      LoggerService.log("Groq Error: Timeout after 30s");
      return "Erro: Tempo esgotado (Timeout) no Groq.";
    } catch (e) {
      LoggerService.log("Groq Provider Error: $e");
      return "Erro Groq: $e";
    }
  }
}

class MistralProvider extends AIProvider {
  MistralProvider({required super.apiKey, required super.model, required super.prompt});

  @override
  Future<String?> generateReply(String userMessage, {List<Map<String, String>> history = const []}) async {
    try {
      final url = Uri.parse('https://api.mistral.ai/v1/chat/completions');
      
      final List<Map<String, String>> messages = [
        {'role': 'system', 'content': prompt},
        ...history.map((e) => {'role': (e['role'] == 'model' || e['role'] == 'assistant') ? 'assistant' : 'user', 'content': e['message'] ?? ''}),
        {'role': 'user', 'content': userMessage}
      ];

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model.isEmpty ? 'mistral-small-latest' : model,
          'messages': messages,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        LoggerService.log("Mistral Error: ${response.statusCode} - ${response.body}");
        if (response.statusCode == 429) return "Erro 429: Limite de uso atingido no Mistral.";
        return "Erro Mistral (${response.statusCode}): ${response.body}";
      }
    } on TimeoutException {
      LoggerService.log("Mistral Error: Timeout after 30s");
      return "Erro: Tempo esgotado (Timeout) no Mistral.";
    } catch (e) {
      LoggerService.log("Mistral Provider Error: $e");
      return "Erro Mistral: $e";
    }
  }
}

class OpenRouterProvider extends AIProvider {
  OpenRouterProvider({required super.apiKey, required super.model, required super.prompt});

  @override
  Future<String?> generateReply(String userMessage, {List<Map<String, String>> history = const []}) async {
    try {
      final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
      
      final List<Map<String, String>> messages = [
        {'role': 'system', 'content': prompt},
        ...history.map((e) => {'role': (e['role'] == 'model' || e['role'] == 'assistant') ? 'assistant' : 'user', 'content': e['message'] ?? ''}),
        {'role': 'user', 'content': userMessage}
      ];

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://github.com/clept/automacao-whatsapp', // OpenRouter recommend sending this
          'X-Title': 'Whatsapp AutoReply',
        },
        body: jsonEncode({
          'model': model.isEmpty ? 'google/gemini-2.0-flash-exp:free' : model,
          'messages': messages,
        }),
      ).timeout(const Duration(seconds: 45)); // OpenRouter acts as proxy and is often slower sometimes

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        LoggerService.log("OpenRouter Error: ${response.statusCode} - ${response.body}");
        if (response.statusCode == 429) return "Erro 429: Limite de uso atingido na OpenRouter para sua conta (ou modelo sem slots disponíveis).";
        return "Erro OpenRouter (${response.statusCode}): ${response.body}";
      }
    } on TimeoutException {
      LoggerService.log("OpenRouter Error: Timeout after 45s");
      return "Erro: Tempo esgotado (Timeout 45s) no roteador da OpenRouter.";
    } catch (e) {
      LoggerService.log("OpenRouter Provider Error: $e");
      return "Erro OpenRouter: $e";
    }
  }
}
