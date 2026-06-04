import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/document_provider.dart';
import '../../widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, double> _summary = {};
  bool _loadingSummary = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final companyProvider = context.read<CompanyProvider>();
    final docProvider = context.read<DocumentProvider>();
    await companyProvider.loadCompanies();

    if (companyProvider.hasCompany) {
      final now = DateTime.now();
      final firstOfMonth = DateTime(now.year, now.month, 1);
      _summary = await docProvider.getSalesSummary(
        companyProvider.currentCompany!.id!,
        firstOfMonth,
        now,
      );
    }
    _loadingSummary = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Consumer<CompanyProvider>(
              builder: (context, companyProv, _) {
                if (!companyProv.hasCompany) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.business, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No hay empresa registrada'),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/companies'),
                            icon: const Icon(Icons.add),
                            label: const Text('Registrar Empresa'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.business,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(companyProv.currentCompany!.businessName),
                    subtitle: Text('RUC: ${companyProv.currentCompany!.ruc}'),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            if (!_loadingSummary && _summary.isNotEmpty)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildSummaryCard(
                    theme,
                    'Ventas del Mes',
                    currencyFormat.format(_summary['total_sales'] ?? 0),
                    Icons.trending_up,
                    Colors.green,
                  ),
                  _buildSummaryCard(
                    theme,
                    'Documentos',
                    '${(_summary['total_docs'] ?? 0).toInt()}',
                    Icons.description,
                    Colors.blue,
                  ),
                  _buildSummaryCard(
                    theme,
                    'Facturas',
                    currencyFormat.format(_summary['total_facturas'] ?? 0),
                    Icons.receipt_long,
                    Colors.indigo,
                  ),
                  _buildSummaryCard(
                    theme,
                    'Boletas',
                    currencyFormat.format(_summary['total_boletas'] ?? 0),
                    Icons.receipt,
                    Colors.teal,
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acciones Rápidas',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            theme,
                            icon: Icons.add_shopping_cart,
                            label: 'Nueva Venta',
                            onTap: () =>
                                Navigator.pushNamed(context, '/sales/new'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            theme,
                            icon: Icons.people,
                            label: 'Clientes',
                            onTap: () =>
                                Navigator.pushNamed(context, '/customers'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            theme,
                            icon: Icons.inventory,
                            label: 'Productos',
                            onTap: () =>
                                Navigator.pushNamed(context, '/products'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 12)),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AppDrawer(
      userName: auth.currentUser?.fullName ?? '',
      userRole: auth.currentUser?.role ?? '',
      onDashboard: () => Navigator.pop(context),
      onSales: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/sales/new');
      },
      onProducts: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/products');
      },
      onCustomers: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/customers');
      },
      onCompanies: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/companies');
      },
      onReports: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/reports');
      },
      onApiStats: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/reports/api-stats');
      },
      onSettings: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/settings');
      },
      onLogout: () {
        Navigator.pop(context);
        context.read<AuthProvider>().logout();
        Navigator.pushReplacementNamed(context, '/login');
      },
    );
  }
}
