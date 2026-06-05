import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'services/db_init.dart';
import 'services/sync_service.dart';
import 'services/settings_service.dart';
import 'models/customer.dart';
import 'providers/auth_provider.dart';
import 'providers/company_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/product_provider.dart';
import 'providers/document_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/company/company_list_screen.dart';
import 'screens/company/company_form_screen.dart';
import 'screens/customer/customer_list_screen.dart';
import 'screens/customer/customer_form_screen.dart';
import 'screens/customer/customer_history_screen.dart';
import 'screens/product/product_list_screen.dart';
import 'screens/product/product_form_screen.dart';
import 'screens/sales/sales_list_screen.dart';
import 'screens/sales/new_sale_screen.dart';
import 'screens/sales/sale_detail_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/reports/api_stats_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initDatabaseFactory();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.publishableKey,
  );

  SyncService.instance.init();

  final settings = SettingsService();
  final themeMode = await settings.getThemeMode();

  runApp(FactureApp(initialThemeMode: themeMode));
}

class FactureApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  const FactureApp({super.key, required this.initialThemeMode});

  static FactureAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<FactureAppState>();
  }

  @override
  State<FactureApp> createState() => FactureAppState();
}

class FactureAppState extends State<FactureApp> {
  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
      ],
      child: MaterialApp(
        title: 'Facture',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        initialRoute: '/login',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              );
            case '/dashboard':
              return MaterialPageRoute(
                builder: (_) => const DashboardScreen(),
              );
            case '/companies':
              return MaterialPageRoute(
                builder: (_) => const CompanyListScreen(),
              );
            case '/companies/form':
              return MaterialPageRoute(
                builder: (_) => const CompanyFormScreen(),
              );
            case '/customers':
              return MaterialPageRoute(
                builder: (_) => const CustomerListScreen(),
              );
            case '/customers/form':
              return MaterialPageRoute(
                builder: (_) => const CustomerFormScreen(),
              );
            case '/customers/history':
              final custArg = settings.arguments;
              if (custArg is Customer) {
                return MaterialPageRoute(
                  builder: (_) => CustomerHistoryScreen(customer: custArg),
                );
              }
              return MaterialPageRoute(
                builder: (_) => const CustomerListScreen(),
              );
            case '/products':
              return MaterialPageRoute(
                builder: (_) => const ProductListScreen(),
              );
            case '/products/form':
              return MaterialPageRoute(
                builder: (_) => const ProductFormScreen(),
              );
            case '/sales':
              return MaterialPageRoute(
                builder: (_) => const SalesListScreen(),
              );
            case '/sales/new':
              return MaterialPageRoute(
                builder: (_) => const NewSaleScreen(),
              );
            case '/reports':
              return MaterialPageRoute(
                builder: (_) => const ReportsScreen(),
              );
            case '/reports/api-stats':
              return MaterialPageRoute(
                builder: (_) => const ApiStatsScreen(),
              );
            case '/settings':
              return MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              );
            default:
              if (settings.name?.startsWith('/sales/') ?? false) {
                final id = int.tryParse(settings.name!.split('/').last);
                if (id != null) {
                  return MaterialPageRoute(
                    builder: (_) => SaleDetailScreen(documentId: id),
                  );
                }
              }
              return MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              );
          }
        },
      ),
    );
  }
}
