import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auto_reply_rule.dart';

class AutoReplyRepository {
  static const String _keyIsEnabled = 'auto_reply_enabled';
  static const String _keyMessage = 'auto_reply_message';
  static const String _keyRules = 'auto_reply_rules';
  
  // AI Keys
  static const String _keyAiEnabled = 'ai_auto_reply_enabled';
  static const String _keyAiApiKey = 'ai_api_key';
  static const String _keyAiPrompt = 'ai_prompt';
  static const String _keyAiModel = 'ai_model';
  static const String _keyAiProvider = 'ai_provider';
  static const String _keyReplyDelay = 'reply_delay'; // in seconds
  static const String _keySimulateTyping = 'simulate_typing';
  static const String _keyFloatingButton = 'floating_toggle_button';
  static const String _keyDebounceDelay = 'debounce_delay'; // in seconds

  static const String _keyClaudeKey = 'claude_api_key';
  static const String _keyDeepSeekKey = 'deepseek_api_key';
  static const String _keyGroqKey = 'groq_api_key';
  static const String _keyMistralKey = 'mistral_api_key';
  static const String _keyOpenRouterKey = 'openrouter_api_key';

  Future<SharedPreferences> _getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  Future<String> getAiModel() async {
    final prefs = await _getPrefs();
    String model = prefs.getString(_keyAiModel) ?? 'llama-3.1-8b-instant';
    if (model == 'gemini-1.5-flash-latest' || model == 'gemini-1.5-flash') return 'llama-3.1-8b-instant';
    return model;
  }

  Future<void> setAiModel(String model) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyAiModel, model);
  }

  Future<String> getAiProvider() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyAiProvider) ?? 'Groq';
  }

  Future<void> setAiProvider(String provider) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyAiProvider, provider);
  }

  Future<int> getReplyDelay() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyReplyDelay) ?? 3; // Default 3 seconds
  }

  Future<void> setReplyDelay(int seconds) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyReplyDelay, seconds);
  }

  Future<int> getDebounceDelay() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyDebounceDelay) ?? 4; // Default 4 seconds
  }

  Future<void> setDebounceDelay(int seconds) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyDebounceDelay, seconds);
  }

  Future<bool> isSimulateTypingEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keySimulateTyping) ?? false;
  }

  Future<void> setSimulateTypingEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keySimulateTyping, enabled);
  }

  Future<bool> isFloatingButtonEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyFloatingButton) ?? false;
  }

  Future<void> setFloatingButtonEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyFloatingButton, enabled);
  }

  Future<bool> isAutoReplyEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyIsEnabled) ?? false;
  }

  Future<void> setAutoReplyEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyIsEnabled, enabled);
  }

  Future<String> getAutoReplyMessage() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyMessage) ?? "Estou ausente no momento. Responderei assim que possível.";
  }

  Future<void> setAutoReplyMessage(String message) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyMessage, message);
  }

  Future<List<AutoReplyRule>> getRules() async {
    final prefs = await _getPrefs();
    final String? rulesJson = prefs.getString(_keyRules);
    if (rulesJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(rulesJson);
    return decoded.map((e) => AutoReplyRule.fromJson(e)).toList();
  }

  Future<void> saveRules(List<AutoReplyRule> rules) async {
    final prefs = await _getPrefs();
    final String encoded = jsonEncode(rules.map((e) => e.toJson()).toList());
    await prefs.setString(_keyRules, encoded);
  }

  // AI Methods
  Future<bool> isAiEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyAiEnabled) ?? false;
  }

  Future<void> setAiEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyAiEnabled, enabled);
  }

  Future<String?> getAiApiKey() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyAiApiKey);
  }

  Future<void> setAiApiKey(String apiKey) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyAiApiKey, apiKey);
  }

  Future<String> getAiPrompt() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyAiPrompt) ?? 
      "Você é um assistente virtual útil e educado. Responda de forma curta e direta.";
  }

  Future<void> setAiPrompt(String prompt) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyAiPrompt, prompt);
  }

  // Provider Specific Methods
  Future<String?> getClaudeKey() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyClaudeKey);
  }

  Future<void> setClaudeKey(String key) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyClaudeKey, key);
  }

  Future<String?> getDeepSeekKey() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyDeepSeekKey);
  }

  Future<void> setDeepSeekKey(String key) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyDeepSeekKey, key);
  }

  Future<String?> getGroqKey() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyGroqKey);
  }

  Future<void> setGroqKey(String key) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyGroqKey, key);
  }

  Future<String?> getMistralKey() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyMistralKey);
  }

  Future<void> setMistralKey(String key) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyMistralKey, key);
  }

  Future<String?> getOpenRouterKey() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyOpenRouterKey);
  }

  Future<void> setOpenRouterKey(String key) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyOpenRouterKey, key);
  }

  Future<Map<String, String>> getAvailableProviders() async {
    final Map<String, String> available = {};
    
    final gemini = await getAiApiKey();
    if (gemini != null && gemini.isNotEmpty) available['Gemini'] = gemini;
    
    final claude = await getClaudeKey();
    if (claude != null && claude.isNotEmpty) available['Claude'] = claude;
    
    final deepseek = await getDeepSeekKey();
    if (deepseek != null && deepseek.isNotEmpty) available['DeepSeek'] = deepseek;
    
    final groq = await getGroqKey();
    if (groq != null && groq.isNotEmpty) available['Groq'] = groq;

    final mistral = await getMistralKey();
    if (mistral != null && mistral.isNotEmpty) available['Mistral'] = mistral;

    final openRouter = await getOpenRouterKey();
    if (openRouter != null && openRouter.isNotEmpty) available['OpenRouter'] = openRouter;
    
    return available;
  }
}

