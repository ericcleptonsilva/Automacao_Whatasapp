import 'ai_providers.dart';
import '../repositories/auto_reply_repository.dart';
import '../repositories/crm_repository.dart';
import '../repositories/campaign_repository.dart';
import 'logger_service.dart';

class AIService {
  final AutoReplyRepository _repository = AutoReplyRepository();
  final CRMRepository _crmRepository = CRMRepository();
  final CampaignRepository _campaignRepository = CampaignRepository();

  // Singletons for local services

  // Flag to globally disable MediaPipe if running in background isolate
  static bool isBackgroundContext = false;

  Future<String?> generateReply(
    String userMessage, {
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final prompt = await _repository.getAiPrompt();

      // Normalize decommissioned models from repository
      var model = await _repository.getAiModel();
      if (model == 'llama3-8b-8192') model = 'llama-3.1-8b-instant';
      if (model == 'google/gemini-2.0-flash-lite-preview-02-05:free' ||
          model == 'google/gemini-2.0-flash-lite-preview') {
        model = 'google/gemini-2.0-flash-exp:free';
      }

      final fullPrompt = await _buildPrompt(prompt);

      final primaryProvider = await _repository.getAiProvider();
      final availableProviders = await _repository.getAvailableProviders();

      // Create a priority list: primary first, then others
      final List<String> fallbackOrder = [primaryProvider];
      for (var p in availableProviders.keys) {
        if (p != primaryProvider) fallbackOrder.add(p);
      }

      for (var providerName in fallbackOrder) {
        final apiKey = availableProviders[providerName];
        if (apiKey == null || apiKey.isEmpty) {
          LoggerService.log(
            "AIService: No API key for $providerName. Skipping.",
          );
          continue;
        }

        // Use the selected model only for the primary provider.
        // For fallback providers, use a safe default compatible with their SDK.
        final currentModel = (providerName == primaryProvider)
            ? model
            : _getDefaultModelFor(providerName);

        AIProvider? provider;
        switch (providerName) {
          case 'Gemini':
            provider = GeminiProvider(
              apiKey: apiKey,
              model: currentModel,
              prompt: fullPrompt,
            );
            break;
          case 'Claude':
            provider = ClaudeProvider(
              apiKey: apiKey,
              model: currentModel,
              prompt: fullPrompt,
            );
            break;
          case 'DeepSeek':
            provider = DeepSeekProvider(
              apiKey: apiKey,
              model: currentModel,
              prompt: fullPrompt,
            );
            break;
          case 'Groq':
            provider = GroqProvider(
              apiKey: apiKey,
              model: currentModel,
              prompt: fullPrompt,
            );
            break;
          case 'Mistral':
            provider = MistralProvider(
              apiKey: apiKey,
              model: currentModel,
              prompt: fullPrompt,
            );
            break;
          case 'OpenRouter':
            provider = OpenRouterProvider(
              apiKey: apiKey,
              model: currentModel,
              prompt: fullPrompt,
            );
            break;
        }

        if (provider == null) continue;

        LoggerService.log(
          "AIService: generating reply using $providerName (Model: $currentModel)...",
        );
        try {
          final response = await provider.generateReply(
            userMessage,
            history: history,
          );

          if (response != null) {
            if (response.startsWith("Erro")) {
              LoggerService.log(
                "AIService: $providerName failed with error: $response. Trying fallback...",
              );
              continue;
            }
            LoggerService.log(
              "AIService: Successfully generated reply using $providerName.",
            );
            return response;
          } else {
            LoggerService.log(
              "AIService: $providerName returned null response.",
            );
          }
        } catch (e) {
          LoggerService.log(
            "AIService: Exception while generating reply with $providerName: $e",
          );
        }
      }

      /*
      print("AIService: Online providers failed. Checking MediaPipe Local LLM as fallback...");
      if (isBackgroundContext) {
        print("AIService: ⚠️ Skipping Local LLM (MediaPipe) because we are inside a Background Isolate.");
      } else {
        try {
          if (await _localLLM.isReady()) {
            final localResponse = await _localLLM.generateReply(userMessage, history: history);
            if (localResponse != null) {
              print("AIService: Successfully generated reply using Local LLM.");
              return localResponse;
            }
          }
        } catch (e) {
          print("AIService: Local LLM failed with critical error: $e");
        }
      }
      */

      LoggerService.log(
        "AIService: All providers (online and offline) failed.",
      );
      return null;
    } catch (e, stack) {
      LoggerService.log(
        "AIService: CRITICAL ERROR in fallback loop: $e\n$stack",
      );
      return null;
    }
  }

  Future<String> _buildPrompt(String basePrompt) async {
    var prompt = basePrompt;

    // Inject CRM Departments into Prompt
    final departments = await _crmRepository.getDepartments();
    if (departments.isNotEmpty) {
      final buffer = StringBuffer();
      buffer.writeln("\n\nINSTRUÇÕES DO SISTEMA - DEPARTAMENTOS:");
      buffer.writeln("A empresa possui os seguintes departamentos:");
      for (var dept in departments) {
        buffer.writeln(
          "- ${dept.name}: ${dept.phoneNumber} (${dept.description})",
        );
      }
      buffer.writeln(
        "Se o usuário solicitar falar com um desses departamentos, forneça o link: https://wa.me/<NUMERO_DO_DEPARTAMENTO> e seja educado.",
      );
      prompt += buffer.toString();
    }

    // Inject Campaign Context into Prompt
    final campaignMessage = await _campaignRepository.getCampaignMessage();
    if (campaignMessage != null && campaignMessage.isNotEmpty) {
      final campaignDate = await _campaignRepository.getCampaignDate();
      final buffer = StringBuffer();
      buffer.writeln("\n\n🚀 CONTEXTO CRÍTICO DE CAMPANHA RECENTE:");
      buffer.writeln(
        "A empresa enviou recentemente uma campanha para seus clientes com o seguinte conteúdo:",
      );
      buffer.writeln("\"$campaignMessage\"");
      if (campaignDate != null) {
        buffer.writeln("Data e hora da campanha: $campaignDate");
      }
      buffer.writeln(
        "IMPORTANTE: Se o cliente responder de forma curta ou perguntar algo que pareça interessado no assunto acima, assuma que ele recebeu essa campanha.",
      );
      buffer.writeln(
        "Sua missão é converter esse interesse em atendimento ou venda baseada no que foi oferecido acima.",
      );

      prompt += buffer.toString();
      LoggerService.log("AIService: Injected campaign context into prompt.");
    }
    return prompt;
  }

  String _getDefaultModelFor(String providerName) {
    switch (providerName) {
      case 'Gemini':
        return 'gemini-2.0-flash';
      case 'Claude':
        return 'claude-3-haiku-20240307';
      case 'DeepSeek':
        return 'deepseek-chat';
      case 'Groq':
        return 'llama-3.1-8b-instant';
      case 'Mistral':
        return 'mistral-small-latest';
      case 'OpenRouter':
        return 'google/gemini-2.0-flash-exp:free';
      default:
        return '';
    }
  }
}
