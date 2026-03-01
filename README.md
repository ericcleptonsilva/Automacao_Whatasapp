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

### Melhorias na Automação Nativa e Campanhas
- **Delay Cognitivo de Acessibilidade:** Em versões recentes do Android, a renderização de UI do WhatsApp tem um pequeno atraso. Modificamos o `WhatsAppAccessibilityService` nativo (Kotlin) instanciando um loop de retry assíncrono com delay (`Handler.postDelayed`). Isso resolve o bug crítico onde Campanhas abriam os contatos no WhatsApp, mas não clicavam no botão "Enviar".
- **Sincronia de IDs:** Foram adicionados múltiplos selectors de Layout ("Send", "Enviar") e Node IDs atualizados do Business e Pessoal para ampliar a detecção de clique em dispositivos rápidos e lentos.

---
Para detalhes técnicos e logs de erros, consulte o arquivo [ISSUES.md](file:///c:/Users/clept/Documents/APPS/Automacao_Whatasapp/ISSUES.md).
