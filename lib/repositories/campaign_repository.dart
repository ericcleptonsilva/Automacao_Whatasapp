import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/campaign_log.dart';

class CampaignRepository {
  static const String _keyCampaignMessage = 'last_campaign_message';
  static const String _keyCampaignDate = 'last_campaign_date';
  static const String _keyCampaignLogs = 'campaign_logs_v2';
  static const String _keyCampaignDraft = 'campaign_message_draft';

  Future<SharedPreferences> _getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  Future<void> saveDraft(String message) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyCampaignDraft, message);
  }

  Future<String?> getDraft() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyCampaignDraft);
  }

  Future<void> saveCampaignMessage(String message) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyCampaignMessage, message);
    await prefs.setString(_keyCampaignDate, DateTime.now().toIso8601String());
  }

  Future<String?> getCampaignMessage() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyCampaignMessage);
  }

  Future<String?> getCampaignDate() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyCampaignDate);
  }

  Future<List<CampaignLog>> getLogs() async {
    final prefs = await _getPrefs();
    final List<String> logsJson = prefs.getStringList(_keyCampaignLogs) ?? [];
    return logsJson
        .map((json) => CampaignLog.fromJson(jsonDecode(json)))
        .toList()
        .reversed
        .toList(); // Newest first
  }

  Future<void> addLog(CampaignLog log) async {
    final prefs = await _getPrefs();
    final List<String> logsJson = prefs.getStringList(_keyCampaignLogs) ?? [];
    logsJson.add(jsonEncode(log.toJson()));
    
    // Limit to last 50 campaigns to save space
    if (logsJson.length > 50) {
      logsJson.removeAt(0);
    }
    
    await prefs.setStringList(_keyCampaignLogs, logsJson);
  }

  Future<void> clearCampaignMessage() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyCampaignMessage);
    await prefs.remove(_keyCampaignDate);
  }
}
