import 'package:flutter/material.dart';
import 'sync_status.dart';

class AppDrawer extends StatelessWidget {
  final String userName;
  final String userRole;
  final VoidCallback onDashboard;
  final VoidCallback onSales;
  final VoidCallback onProducts;
  final VoidCallback onCustomers;
  final VoidCallback onCompanies;
  final VoidCallback onReports;
  final VoidCallback onApiStats;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.userRole,
    required this.onDashboard,
    required this.onSales,
    required this.onProducts,
    required this.onCustomers,
    required this.onCompanies,
    required this.onReports,
    required this.onApiStats,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    userName.isNotEmpty
                        ? userName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 28,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userRole,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          _buildMenuItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            onTap: onDashboard,
          ),
          _buildMenuItem(
            icon: Icons.point_of_sale,
            label: 'Nueva Venta',
            onTap: onSales,
          ),
          _buildMenuItem(
            icon: Icons.inventory,
            label: 'Productos',
            onTap: onProducts,
          ),
          _buildMenuItem(
            icon: Icons.people,
            label: 'Clientes',
            onTap: onCustomers,
          ),
          _buildMenuItem(
            icon: Icons.business,
            label: 'Empresas',
            onTap: onCompanies,
          ),
          _buildMenuItem(
            icon: Icons.bar_chart,
            label: 'Reportes',
            onTap: onReports,
          ),
          _buildMenuItem(
            icon: Icons.query_stats,
            label: 'Estadísticas API',
            onTap: onApiStats,
          ),
          _buildMenuItem(
            icon: Icons.settings,
            label: 'Configuración',
            onTap: onSettings,
          ),
          const Spacer(),
          const SyncStatus(),
          const Divider(),
          _buildMenuItem(
            icon: Icons.logout,
            label: 'Cerrar Sesión',
            onTap: onLogout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
