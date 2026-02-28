# Automação WhatsApp - Guia de Execução

Este aplicativo utiliza serviços de Acessibilidade e Leitura de Notificações do Android para automatizar o envio e resposta de mensagens no WhatsApp.

## Pré-requisitos
- Dispositivo Android (Físico ou Emulador com Google Play).
- WhatsApp instalado e logado.
- Modo Desenvolvedor ativado no Android (para rodar via USB).

## Como Rodar
1. Conecte seu dispositivo Android via USB.
2. No terminal, na pasta do projeto, execute:
   ```bash
   flutter run
   ```

## Configuração Necessária (No Android)
Ao abrir o app pela primeira vez, você verá o Dashboard com indicadores vermelhos. Siga os passos:

### 1. Habilitar Serviço de Acessibilidade
- Clique no card ou botão para abrir as Configurações de Acessibilidade.
- Procure por **WhatsApp Automation** (ou `whatsapp_auto`).
- Ative o interruptor.
- **Nota**: O Android pode exibir um aviso de segurança. Isso é normal para apps de acessibilidade instalados fora da Play Store. Permita para continuar.

### 2. Habilitar Leitor de Notificações (Opcional, para auto-resposta)
- Clique no card "Notification Listener".
- Nas configurações, ative o acesso para **WhatsApp Automation**.

## Como Testar
1. No Dashboard, digite um número de telefone com código do país (ex: `558599...`).
2. Digite uma mensagem.
3. Clique em **Open WhatsApp & Send**.
4. O app abrirá a conversa e o Serviço de Acessibilidade deverá detectar o botão de enviar e clicar automaticamente (pode haver um pequeno delay proposital).

## Solução de Problemas
- **O botão de enviar não clica**: Verifique se o texto do botão é "Enviar" ou "Send". O serviço busca por esses termos. Se o seu WhatsApp estiver em outro idioma, pode precisar de ajuste no código.
- **Erro de Compilação**: Certifique-se de que o SDK do Android está atualizado. Tente `flutter clean` e `flutter pub get`.
