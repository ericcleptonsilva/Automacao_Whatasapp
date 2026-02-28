import 'dart:isolate';
import 'package:flutter/foundation.dart'; // Add this for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/native_service.dart';
import 'ui/contacts_screen.dart';
import 'ui/campaign_screen.dart';
import 'ui/notification_log_screen.dart';
import 'ui/auto_reply_screen.dart';
import 'ui/meta_api_settings_screen.dart';
import 'ui/crm_screen.dart';
import 'ui/campaign_history_screen.dart';
import 'ui/llm_management_screen.dart';
import 'services/auto_reply_service.dart';
import 'services/background_service.dart';
import 'services/ad_service.dart';
import 'services/logger_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.initialize();
  
  // Ensure we only initialize the service from the UI Isolate
  final bool isMainIsolate = Isolate.current.debugName == 'main' || Isolate.current.debugName == null;
  
  if (isMainIsolate) {
    try {
      final service = FlutterBackgroundService();
      if (!await service.isRunning()) {
        await initializeBackgroundService();
      } else {
      LoggerService.log("BackgroundService: Already running, skipping initialization in main.");
      }
    } catch (e) {
      LoggerService.log("BackgroundService initialization info: $e");
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServiceStatusProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class ServiceStatusProvider extends ChangeNotifier {
  final NativeService _nativeService = NativeService();
  bool isAccessibilityEnabled = false;
  bool isNotificationEnabled = false;
  bool isBatteryOptimizationIgnored = false;
  bool isServiceRunning = false;

  Future<void> checkStatus() async {
    if (kIsWeb) return;
    isAccessibilityEnabled = await _nativeService.isAccessibilityServiceEnabled();
    isNotificationEnabled = await _nativeService.isNotificationListenerEnabled();
    isBatteryOptimizationIgnored = await _nativeService.isIgnoringBatteryOptimizations();
    notifyListeners();
  }

  Future<void> openAccessibilitySettings() async {
    await _nativeService.openAccessibilitySettings();
    // Wait for user to come back? Or just check again on resume.
  }

  Future<void> openNotificationSettings() async {
    await _nativeService.openNotificationListenerSettings();
  }

  Future<void> openAppSettings() async {
    await _nativeService.openAppSettings();
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    await _nativeService.requestIgnoreBatteryOptimizations();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automação WhatsApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF075E54), // WhatsApp Teal
          secondary: const Color(0xFF25D366), // WhatsApp Light Green
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF075E54),
          foregroundColor: Colors.white,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  
  final AutoReplyService _autoReplyService = AutoReplyService();
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd(
      onAdLoaded: (ad) {
        setState(() {
          _isBannerAdLoaded = true;
        });
      },
      onAdFailedToLoad: (ad, error) {
      LoggerService.log('BannerAd failed to load: $error');
        ad.dispose();
      },
    )..load();
  }

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    WidgetsBinding.instance.addObserver(this);
    // Check initial status
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ServiceStatusProvider>().checkStatus();
      
      // Coordination: If background service is likely running, 
      // we might want to skip UI listening to avoid duplicates.
      // For now, we'll start it but added safety in AutoReplyService (cooldown/processing).
      // A more robust way is checking if the service is active:
      try {
        final isServiceRunning = await FlutterBackgroundService().isRunning();
        if (!isServiceRunning) {
        LoggerService.log("Dashboard: Background service not running, starting UI listener branch.");
          _autoReplyService.startListening();
        } else {
        LoggerService.log("Dashboard: Background service already active.");
        }
      } catch (e) {
      LoggerService.log("Dashboard: Error checking background service status: $e");
        // Fallback: start listening in UI if we can't confirm background service
        _autoReplyService.startListening();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    // _autoReplyService.stopListening(); // Keep running in background
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ServiceStatusProvider>().checkStatus();
    }
  }

  void _showSamsungHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text("Ajuda: Android 13/14"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Em celulares Samsung (A03, etc) com Android 13+, a Acessibilidade vem bloqueada por padrão.",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text("PASSO A PASSO PARA ATIVAR:"),
              const SizedBox(height: 8),
              const Text("1. Clique no botão abaixo 'ABRIR CONFIGS DO APP'."),
              const Text("2. Se vir os 3 pontinhos (⋮) no topo, clique neles e selecione 'Permitir configurações restritas'."),
              const SizedBox(height: 8),
              const Text("SE NÃO VIR OS 3 PONTINHOS:", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const Text("1. Rola a tela das Configurações do App até o final."),
              const Text("2. Procure pela opção 'PERMITIR CONFIGURAÇÕES RESTRITAS' em baixo da última opção de menu."),
              const Text("3. Clique nela e coloque sua senha/biometria."),
              const SizedBox(height: 12),
              const Text("Após isso, volte aqui e ative a Acessibilidade normalmente."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("FECHAR"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ServiceStatusProvider>().openAppSettings();
            },
            child: const Text("ABRIR CONFIGS DO APP"),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final statusProvider = context.watch<ServiceStatusProvider>();

    return Scaffold(
      drawer: NavigationDrawer(
        onDestinationSelected: (index) {
           Navigator.pop(context); // Close drawer
           switch (index) {
             case 0: // Dashboard - do nothing or scroll top
               break;
             case 1:
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()));
               break;
             case 2:
               Navigator.push(context, MaterialPageRoute(builder: (_) => const CampaignScreen()));
               break;
             case 3:
               Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationLogScreen()));
               break;
             case 4:
               Navigator.push(context, MaterialPageRoute(builder: (_) => const AutoReplyScreen()));
               break;
             case 5:
               Navigator.push(context, MaterialPageRoute(builder: (_) => const MetaApiSettingsScreen()));
               break;
             case 6:
               Navigator.push(context, MaterialPageRoute(builder: (_) => const CRMScreen()));
               break;
             case 7:
               Navigator.push(context, MaterialPageRoute(builder: (_) => const CampaignHistoryScreen()));
               break;
             case 8:
               Navigator.push(context, MaterialPageRoute(builder: (_) => const LLMManagementScreen()));
               break;
           }
        },
        selectedIndex: 0, // Dashboard is always 0 in this context
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              'Automação WhatsApp',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: Text('Painel'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: Text('Contatos'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: Text('Campanha'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: Text('Histórico'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: Text('Regras'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.api_outlined),
            selectedIcon: Icon(Icons.api),
            label: Text('Config API'),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
            child: Divider(),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: Text('CRM / Departamentos'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.history_edu_outlined),
            selectedIcon: Icon(Icons.history_edu),
            label: Text('Histórico Campanhas'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.memory_outlined),
            selectedIcon: Icon(Icons.memory),
            label: Text('I.A. Local Avançada 🚀'),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text('Status dos Serviços'),
          ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 28),
             child: Column(
               children: [
                 SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    secondary: Icon(statusProvider.isAccessibilityEnabled ? Icons.check_circle : Icons.error, 
                      color: statusProvider.isAccessibilityEnabled ? Colors.green : Colors.red, size: 22),
                    title: const Text("Acessibilidade"),
                    value: statusProvider.isAccessibilityEnabled,
                    onChanged: (val) => statusProvider.openAccessibilitySettings(),
                  ),
                   SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    secondary: Icon(statusProvider.isNotificationEnabled ? Icons.check_circle : Icons.error, 
                      color: statusProvider.isNotificationEnabled ? Colors.green : Colors.red, size: 22),
                    title: const Text("Notificações"),
                    value: statusProvider.isNotificationEnabled,
                    onChanged: (val) => statusProvider.openNotificationSettings(),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    secondary: Icon(statusProvider.isBatteryOptimizationIgnored ? Icons.check_circle : Icons.battery_alert, 
                      color: statusProvider.isBatteryOptimizationIgnored ? Colors.green : Colors.orange, size: 22),
                    title: const Text("Otimização Bateria"),
                    value: statusProvider.isBatteryOptimizationIgnored,
                    onChanged: (val) => statusProvider.requestIgnoreBatteryOptimizations(),
                  ),
               ],
             ),
           ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Painel de Controle'),
            pinned: true,
            floating: true,
            // colors are auto-handled by M3 theme from seed
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Status Cards
                  Row(
                    children: [
                      Expanded(
                        child: buildStatusCard(
                          context, 
                          title: "Acessibilidade", 
                          isEnabled: statusProvider.isAccessibilityEnabled,
                          onTap: statusProvider.openAccessibilitySettings,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildStatusCard(
                          context, 
                          title: "Notificações", 
                          isEnabled: statusProvider.isNotificationEnabled,
                          onTap: statusProvider.openNotificationSettings,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildStatusCard(
                          context, 
                          title: "Bateria", 
                          isEnabled: statusProvider.isBatteryOptimizationIgnored,
                          onTap: statusProvider.requestIgnoreBatteryOptimizations,
                          icon: statusProvider.isBatteryOptimizationIgnored ? Icons.battery_charging_full : Icons.battery_alert,
                        ),
                      ),
                    ],
                  ),
                  if (!statusProvider.isAccessibilityEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: const Text("Problemas Ativando no Android 13/14?"),
                        onPressed: () => _showSamsungHelp(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Acesso Rápido", style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3, // Changed from 2 to 3 to be more compact
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                    children: [
                      buildShortcutCard(context, icon: Icons.campaign, label: "Campanha", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CampaignScreen()))),
                      buildShortcutCard(context, icon: Icons.people, label: "Contatos", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()))),
                      buildShortcutCard(context, icon: Icons.history, label: "Histórico", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationLogScreen()))),
                      buildShortcutCard(context, icon: Icons.smart_toy, label: "Regras", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AutoReplyScreen()))),
                      buildShortcutCard(context, icon: Icons.api, label: "API", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MetaApiSettingsScreen()))),
                       buildShortcutCard(context, icon: Icons.business, label: "CRM", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CRMScreen()))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Destaque Doação
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                           Clipboard.setData(const ClipboardData(text: "5fc448aa-6954-4fcd-b9b1-76d4af8c7d11"));
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text("Chave PIX copiada! Obrigado pelo apoio! ❤️")),
                           );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.favorite, color: Colors.white, size: 28),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Apoie este Projeto!",
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Mantenha o sistema evoluindo. Toque para copiar o PIX.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy, color: Colors.white, size: 16),
                                    SizedBox(width: 8),
                                    Text("Copiar Chave PIX", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_isBannerAdLoaded)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      "AVISO: O risco de banimento do número do WhatsApp pela Meta pelo uso deste aplicativo fica por conta e risco do utilizador. Não nos responsabilizamos por bloqueios ou perdas de conta.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

   Widget buildStatusCard(BuildContext context, {required String title, required bool isEnabled, required VoidCallback onTap, IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: isEnabled ? colorScheme.primaryContainer : (title == "Bateria" ? Colors.orange.withValues(alpha: 0.2) : colorScheme.errorContainer),
      child: InkWell(
        onTap: kIsWeb ? () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Este recurso só está disponível em dispositivos Android.")),
          );
        } : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon ?? (isEnabled ? Icons.check_circle : Icons.error), 
                color: isEnabled ? colorScheme.onPrimaryContainer : (title == "Bateria" ? Colors.orange[900] : colorScheme.onErrorContainer), 
                size: 32),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(color: isEnabled ? colorScheme.onPrimaryContainer : (title == "Bateria" ? Colors.orange[900] : colorScheme.onErrorContainer), fontWeight: FontWeight.bold)),
              Text(kIsWeb ? "Indisponível (Web)" : (isEnabled ? "Ativo" : (title == "Bateria" ? "Restrito" : "Inativo")), 
                style: TextStyle(color: isEnabled ? colorScheme.onPrimaryContainer : (title == "Bateria" ? Colors.orange[900] : colorScheme.onErrorContainer), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildShortcutCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
