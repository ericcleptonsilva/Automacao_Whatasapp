class LocalLLMService {
  Future<bool> isReady() async => false;
  Future<String?> generateReply(String prompt, {List<Map<String, String>> history = const []}) async => null;
  void dispose() {}
}
