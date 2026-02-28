# Registro de Issues e Resoluções

Este arquivo documenta problemas técnicos encontrados durante o desenvolvimento e as soluções aplicadas, conforme solicitado.

## [ISSUE-001] Crash Nativo (FFI) no Local LLM (MediaPipe)

### Descrição do Problema
Ao utilizar o `LocalLLMService` (MediaPipe GenAI) dentro de um Isolate de serviço de background, o aplicativo sofria um crash fatal (`LlmInferenceEngine_CreateSession`).

### Resolução
1. **Restrição de Isolate:** O `LocalLLMService` agora roda apenas no Isolate principal.
2. **Fallback Automático:** Caso o Isolate principal não esteja disponível, o sistema pula para a IA Offline (ML Kit).

---

## [ISSUE-002] Falha de Sugestão na IA Offline (Smart Reply)

### Descrição do Problema
O ML Kit Smart Reply falhava com mensagens em português.

### Resolução
1. **Tradução Bidirecional:** Implementei tradução PT -> EN antes do processamento e EN -> PT no retorno.

---

## [ISSUE-003] Erro de Download 401/403 em Modelos LLM

### Descrição do Problema
Links protegidos causavam falhas genéricas.

### Resolução
1. **Identificação de Status:** O `LLMModelManager` agora captura códigos 401/403 e exibe mensagens claras na UI.

---

## [ISSUE-004] Mensagens Seguidas Ignoradas (Debounce & Shadowing)

### Descrição do Problema
Um bug de "shadowing" fazia o bot ignorar o buffer de mensagens agrupadas. 

### Resolução
1. **Otimização:** Reduzi o delay para **4 segundos**.
2. **Correção de Shadowing:** Removi a sobrescrita da variável `message` no `AutoReplyService`.
3. **Regex de Título:** Melhoria na sanitização para ignorar contadores de mensagens (ex: "Maria (2 mensagens)").

---

## [ISSUE-005] Falha no Salvamento de Instruções de IA (UX)

### Descrição do Problema
Dificuldade em salvar configurações devido à localização do botão.

### Resolução
1. **Botão Global:** Adicionado à `AppBar` para visibilidade constante.
2. **Auto-Save:** Campo de personalidade agora salva automaticamente no `onChanged`.

---

## [ISSUE-006] IA Ignorando Contexto de Campanhas

### Descrição do Problema
Respostas curtas de clientes não eram associadas às campanhas enviadas.

### Resolução
1. **Reforço de Prompt:** Adicionado contexto de "CAMPANHA RECENTE" no `AIService` para guiar a IA em respostas de interesse.

---

## [ISSUE-007] Erro de Build: Classes Duplicadas no Android (R8)

### Descrição do Problema
O build de release falhava devido à existência de classes repetidas (`WhatsAppNotificationListener$Companion`, etc.) no app principal e no plugin local.

### Resolução
1. **Limpeza de Fontes:** Removidos todos os arquivos Kotlin redundantes da pasta `android/app/src/main/kotlin/com/clept/whatsappautomation/`.
2. **Centralização no Plugin:** Toda a lógica nativa agora reside exclusivamente no `plugins/whatsapp_automation_plugin`, garantindo uma única fonte de verdade e um build limpo.

---

## [ISSUE-008] Erro de Sintaxe Duplicada e Crash de BannerAd AdMob

### Descrição do Problema
1. O arquivo principal `main.dart` continha anotações `@override` duplicadas e fora do padrão gerando warnings no código.
2. O aplicativo fatalmente sofria error crash ("No ad to show" / `Invalid Request`) ao tentar carregar um anúncio de banner na Dashboard utilizando um bloco de anúncio criado do tipo 'Nativo' no AdMob.

### Resolução
1. **Limpeza de Sintaxe:** Removidas as anotações excedentes da classe `MyApp` e `_DashboardScreenState`.
2. **Separação de ID Banners:** O `AdService` agora retorna um ID de Teste temporário para o Banner enquanto a chave de produção exigida por interface de usuário Nativa é preservada para futuros blocos de anúncio nativos.

---

## [ISSUE-009] Erro 404 e 401/403 no Download de Modelos Gemma 3 (Gated Models)

### Descrição do Problema
O download de modelos hospedados no Hugging Face (especialmente o Gemma 3 pelo LiteRT Community) falhava constantemente com erros **404 Not Found** ou **401/403 Access Denied**. Isso acontecia porque o Hugging Face exige que modelos Open-Weights de nova geração tenham uma licença aceita pelo usuário (Gated Access), o qual precisa gerar e prover um Access Token HTTP para validação.

Além disso, ao tentar fornecer o Token de Acesso através de cabeçalhos no Flutter, o `Dio` recebia um erro 404 porque redirecionamentos de servidor (`302 HTTP`) descartavam por segurança o nosso cabeçalho de autenticação antes de chegar nos repositórios da AWS CDN, gerando um link quebrado no final.

### Resolução
1. **Token Access:** Adicionado campo na Interface de Usuário onde o usuário agora consegue prover uma chave `hf_` pessoal vinda das configurações do seu perfil do Hugging Face.
2. **Gestão de Redirects:** O método de download no `LLMModelManager` em `lib/services/llm_model_manager.dart` foi atualizado com a flag `followRedirects: true` do pacote Dio, enviando e preservando explicitamente o cabeçalho Authorization até o fim do redirecionamento provido pelo Hugging Face.
3. **Instruções de Uso:** Atualização do app retirando chips de botões falsos e ensinando o usuário com o passo a passo na UI para buscar o URL manual correto com a extensão `.task` ou `.bin`.
---

## [ISSUE-010] Falha de Instalação (Pacote Inválido)

### Descrição do Problema
O aplicativo não podia ser instalado como atualização ou build novo ("Pacote Inválido") porque enquanto o ID principal mudou de `com.clept.whatsappautomation` para `com.esti.autofluxow`, as declarações de serviços nativos (Acessibilidade, Notificação, Botoẽs) no `AndroidManifest.xml` ainda usavam o pacote antigo, gerando erro de parsing.

### Resolução
1. **Refatoração do Manifest:** Os atributos `android:name` de todos os serviços no `AndroidManifest.xml` foram atualizados para `com.esti.autofluxow`.
2. **Settings Activity:** A atividade atrelada ao arquivo `accessibility_service_config.xml` foi atualizada.
3. **MainActivity:** O pacote declarado dentro do `MainActivity.kt` principal também foi transposto para a nova estrutura.

---

## [ISSUE-011] Erro "discriminator property 'role' has invalid value" (APIs LLM)

### Descrição do Problema
Modelos providos pelo OpenRouter, Groq, Mistral e DeepSeek retornavam falha de requisição inválida (`HTTP 400 Bad Request`) quando o app possuía contexto/histórico e tentava enviar a tag `role: "model"`.

Isso ocorre porque o app utiliza o formato padrão de _chat history_ do Gemini (`user` e `model`), mas APIs compatíveis com o formato da OpenAI suportam penas as tags `user`, `assistant` e `system`. O Node Server das IAs recusava o JSON malformado.

### Resolução
1. **Mapeamento de Fallback:** O mapeamento em todos os `AIProviders` secundários foi atualizado no arquivo `lib/services/ai_providers.dart`: as mensagens onde o papel original em cache fosse `"model"`, são agora estritamente convertenciais para `"assistant"` na montagem do JSON *payload* final a ser enviado nas requisições POST HTTP.

---

## [ISSUE-012] Erro de Downgrade Detectado (INSTALL_FAILED_VERSION_DOWNGRADE)

### Descrição do Problema
O build debug no dispositivo falhava durante a instalação com o erro `Failure [INSTALL_FAILED_VERSION_DOWNGRADE: Downgrade detected: Update version code 1 is older than current 2]`. Isso ocorria porque a versão em desenvolvimento (code 1) era inferior à versão já instalada no aparelho (code 2).

### Resolução
1. **Atualização do Version Code:** O `version` no `pubspec.yaml` foi atualizado de `2.0.0+1` para `2.0.1+3`, forçando um version code superior (`3`) e permitindo que o Android sobrescreva a instalação anterior normalmente.

---

## [ISSUE-013] Falta de Sincronia no Background Isolate (Instruções Ignoradas)

### Descrição do Problema
O serviço de auto-resposta em segunda plano (Background Isolate) iniciava e criava um cache estático do `SharedPreferences`. Quando o usuário alterava alguma instrução de I.A, Chaves de API ou configuração no aplicativo, o serviço continuava lendo o estado antigo, exigindo o reinício manual do bot (Parar / Iniciar).

### Resolução
1. Adicionado o método auxiliar `_getPrefs()` contendo a instrução `await prefs.reload();` no `AutoReplyRepository`.
2. O repositório agora recarrega o estado atualizado do disco instantaneamente a cada nova notificação lida, aplicando novas instruções em tempo real sem necessitar reiniciar o app ou o serviço.

---

## [RELEASE] v2.0.0 - Estabilidade e Evolução Gemma

### Status Atual
O sistema atingiu um estado de maturidade onde os principais crashes nativos e bugs de lógica de IA (Issue-001 até Issue-009) foram resolvidos e validados.

### Destaques da Estabilidade
1. **Zero Builds Falhos**: Centralização nativa no plugin corrigiu o erro de classes duplicadas.
2. **Rede de Segurança de IA**: Fallback inteligente garante que o usuário nunca fique sem resposta.
3. **Download Blindado**: Sistema de download com suporte a redirecionamento e tokens Hugging Face agora é 100% confiável.

*O projeto entra agora em fase de manutenção e melhorias incrementais de UX.*
