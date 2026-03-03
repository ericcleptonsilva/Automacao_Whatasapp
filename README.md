# Automação de WhatsApp com IA 🚀 v2.0.0 - "Gemma Evolution"

Este projeto é uma ferramenta de automação robusta para responder mensagens do WhatsApp (e WhatsApp Business) utilizando os modelos de IA mais avançados do mercado, com foco em estabilidade, contexto empresarial e execução eficiente.

## 🌟 Funcionalidades de IA de Última Geração

### 1. Sistema de "Cérebro" Expandido
- **Modelos Gemini 2.x e 3.x:** Suporte total à nova geração de modelos do Google.
- **Contexto de Campanhas:** A IA agora tem "memória" de curto prazo sobre as campanhas enviadas. Se um cliente responder a uma oferta, o bot sabe exatamente do que se trata.
- **Agrupamento Inteligente (Debounce):** O bot aguarda 4 segundos para agrupar várias mensagens seguidas do usuário, respondendo ao contexto completo de uma só vez.

### 2. Estabilidade e Segurança (Antigravity Defense)
- **Hierarquia de Fallback:** Se a IA principal falhar, o sistema pula automaticamente para o próximo provedor ou para a IA Local/Offline.
- **Blindagem de Isolate (FFI):** Resolvemos os crashes nativos de background. O app continua vivo mesmo se um modelo local travar.
- **Modo Ausência:** Ative uma resposta padrão global para quando você não puder atender.

### 3. IA Local e Offline Avançada
- **Gemma 3 (MediaPipe):** Suporte direto na palma da mão. Baixe modelos Gemma 3 (270M/1B) com um clique via Presets.
- **ML Kit Smart Reply:** Respostas ultra-rápidas e offline com tradução automática para maior precisão.

## 🎨 Interface e Experiência do Usuário (UX)
- **Salvamento Global:** Botão de salvamento sempre visível no topo da tela. 
- **Auto-Save:** Instruções de personalidade são salvas enquanto você digita para evitar perda de dados.
- **Controle Flutuante:** Botão sobreposto ao WhatsApp para ativar/desativar a automação instantaneamente.

## 🛠️ Configuração Técnica
1. **Instruções de Personalidade:** Defina como o bot deve agir (ex: "Seja um vendedor educado").
2. **Regras de Palavra-Chave:** Defina respostas fixas para perguntas comuns (ex: "Preço", "Endereço").
3. **Delay de Resposta:** Simule um comportamento humano ajustando o tempo de espera.

## 🏆 Marco: Versão 2.0.0 (Gemma Evolution)
Esta versão marca a transição de um protótipo avançado para um produto de nível industrial, integrando as tecnologias mais recentes de IA On-Device e infraestrutura de monetização.

- **IA Local de Próxima Geração**: Integração completa com Gemma 3 (270M/1B).
- **Estabilidade Blindada**: Proteção contra crashes de background e transição inteligente entre modelos.
- **Pronto para Distribuição**: Pacote renomeado (`com.esti.autofluxow`) e AdMob integrado.

## 🔧 Alterações Recentes

### Política de Privacidade (Google Play)
- **Adição de Privacidade:** Criado o documento `PRIVACY_POLICY.md` na raiz do projeto. Ele detalha todas as permissões (Acessibilidade, Contatos, Armazenamento), o uso de integrações de IA de terceiros e a restrição para menores de 13 anos, permitindo o engajamento com conformidades de segurança na Play Console.

### Versão 2.0.1+3
- Atualização da versão no `pubspec.yaml` para corrigir o erro de instalação (Downgrade detectado) durante testes no dispositivo.

### Versão 2.0.0+1
- Atualização oficial de versão no `pubspec.yaml`.
- Centralização completa da lógica nativa no plugin local para builds estáveis.

- **Novo Nome do Pacote:** `com.esti.autofluxow` (Sublocação de `com.clept.whatsappautomation`).
- **AdMob Atualizado:**
    - App ID configurado no `AndroidManifest.xml`.
    - ID de Anúncio Nativo integrado ao `AdService`.
- **Estrutura Kotlin:** Migrada para o novo namespace de pacote.
### Revisão de Código e Bugfixes (AdMob, App e IAs)
- **Otimização de Sintaxe:** Remoção de anotações duplicadas e redundâncias no `main.dart`.
- **Correção AdMob Banner:** Solucionado erro de exibição de banner onde o código solicitava formato estrito *Banner* enviando uma Unit ID de formato *Nativo*. Provisoriamente alterado para blocos de teste seguro para Banners.
- **Correção de Instalação (APK Inválido):** Resolvido problema onde o Android não conseguia instalar o aplicativo porque serviços de Acessibilidade e Notificação ainda referiam o ID do pacote antigo (`com.clept`). O Manifesto foi totalmente migrado para `com.esti.autofluxow`.
- **Correção de Papéis de IA (Invalid Role):** Solucionado o erro `400 Bad Request` retornado pelo OpenRouter, Groq e DeepSeek onde o chat-history da aplicação nativamente formatado em `model` para o Gemini era rejeitado por APIs baseadas em OpenAI, que agora os convertem na hora de enviar ativamente para `assistant`.

- **Sincronização de Chave:** Ao trocar a chave de API nas configurações, é necessário reiniciar o serviço (Parar e Iniciar o Bot) para que o Isolate de segundo plano carregue os novos dados.

### Como Começar (Desenvolvedor)s Locais Avançados (Gemma 3)
- **Hugging Face Authentication:** Modelos de IA modernos como o Gemma 3 são protegidos (Gated). O aplicativo agora suporta inserção de Access Tokens do Hugging Face, enviando cabeçalhos de Autorização corretamente através de redirecionamentos de CDN (AWS) via pacote Dio.
- **Modelos Compatíveis:** Apenas arquivos formatados pela comunidade LiteRT (`.task` ou `.bin` int4/q4) são suportados nativamente pelo MediaPipe on-device.

### Estabilidade da IA e Atualizações (Gemini & MediaPipe)
- **Fallback Inteligente:** Se o modelo `Gemini` online falhar (ex: por chave de API inválida, timeout ou rate limit 429), o sistema acionará imediatamente a Inteligência Artificial Offline Básica (ML Kit) para que o bot nunca pare de responder.
- **Transição de Modelo Fluida:** O aplicativo agora prioriza o `gemini-2.0-flash` como motor principal. Um interceptador converte dinamicamente seleções obsoletas salvas no cache interno para o novo modelo automaticamente.
- **Proteção do Isolate:** A inicialização do MediaPipe (Gemma) foi blindada com uma flag `isBackgroundContext`, prevenindo crashes severos da JNI (Java Native Interface) quando executado em segundo plano.

### Gestão de Campanhas e Acessibilidade
- **Delay Cognitivo de Acessibilidade:** Em versões recentes do Android, a renderização de UI do WhatsApp tem um pequeno atraso. Modificamos o `WhatsAppAccessibilityService` nativo (Kotlin) instanciando um loop de retry assíncrono com delay (`Handler.postDelayed`). Isso resolve o bug crítico onde Campanhas abriam os contatos no WhatsApp, mas não clicavam no botão "Enviar".
- **Sincronia de IDs:** Foram adicionados múltiplos selectors de Layout ("Send", "Enviar") e Node IDs atualizados do Business e Pessoal para ampliar a detecção de clique em dispositivos rápidos e lentos.
- **Envio Nativo Direto + Automação de Câmera:** A nova V2 lida graciosamente com fotos e PDFs tanto para contatos ***salvos quanto não-salvos***. O aplicativo tenta o bypass de "chat-preview" usando a intent nativa `ACTION_SEND` em conjunto com a injeção do JID (`wa.me`), injetado primeiramente pelo **State 5**. Caso a injeção não ocorra e o aplicativo do WhatsApp abra o seu *Contact Picker* bloqueando a listagem (devido a rigidez Anti-Spam), nosso Acessibility Service aciona o **State 6**: A automação entra via teclado invisível (Set text input) pesquisando inteligentemente número por número para então selecioná-lo e enviar a mídia na Listagem de Contatos de forma autônoma sem o toque do usuário.

## ⚖️ Conformidade com Google Play (Metadata & Acessibilidade)

Devido às políticas rigorosas da Google Play Store, este projeto mantém um registro claro de sua descrição e uso de permissões sensíveis.

### Descrição Completa para Google Play Store (pt-BR)

**AutoFluxoW: Automação Inteligente para WhatsApp com IA**

O AutoFluxoW é a ferramenta definitiva de CRM e automação para WhatsApp e WhatsApp Business, agora potencializada pelos modelos mais avançados de Inteligência Artificial do mercado, como o Google Gemini. Transforme seu atendimento ao cliente em um fluxo automatizado, inteligente e eficiente.

**Recursos Principais:**
- **Respostas Inteligentes com IA:** Utilize o poder do Gemini para responder clientes de forma natural e contextualizada.
- **Automação de Campanhas:** Envie mensagens, fotos e PDFs para múltiplos contatos e grupos de forma automática.
- **Interação Contextual:** O "Cérebro" do bot agrupa mensagens e entende o histórico para respostas mais precisas.
- **IA Local e Offline:** Suporte para modelos Gemma 3 e ML Kit para funcionamento mesmo sem internet.
- **Personalidade Customizável:** Defina o tom de voz e as regras de negócio para o seu bot.

**Uso da API de Serviço de Acessibilidade (AccessibilityService API):**
O AutoFluxoW utiliza a **AccessibilityService API** para automatizar interações com o WhatsApp em nome do usuário. Este serviço é essencial para:
1. Detectar e clicar no botão "Enviar" após a composição automatizada de mensagens.
2. Automatizar a pesquisa de contatos no seletor do WhatsApp para envios de campanhas.
3. Facilitar o fluxo de envio de mídias (fotos e documentos) de forma autônoma.

**IMPORTANTE:**
- O serviço de acessibilidade é utilizado estritamente para as funções de automação solicitadas pelo usuário.
- Não coletamos, armazenamos ou compartilhamos dados pessoais ou mensagens privadas através deste serviço.
- O usuário tem total controle e pode desativar a permissão a qualquer momento nas configurações do sistema.

### Histórico de Rejeições e Correções
- **Rejeição (Março 2026):** Problemas de metadados (placeholders de IA) e falta de divulgação clara da API de Acessibilidade.
- **Correção:** Descrição reescrita, placeholders removidos e seção de divulgação de Acessibilidade adicionada conforme exigido pela Política de Dados do Usuário.

---
Para detalhes técnicos e logs de erros, consulte o arquivo [ISSUES.md](file:///c:/Users/clept/Documents/APPS/Automacao_Whatasapp/ISSUES.md).
