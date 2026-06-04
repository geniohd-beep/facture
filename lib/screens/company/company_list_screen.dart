import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/company_provider.dart';

class CompanyListScreen extends StatelessWidget {
  const CompanyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empresas'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/companies/form'),
        child: const Icon(Icons.add),
      ),
      body: Consumer<CompanyProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.companies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No hay empresas registradas'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/companies/form'),
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar Empresa'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.companies.length,
            itemBuilder: (context, index) {
              final company = provider.companies[index];
              final isActive = company.id == provider.currentCompany?.id;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.business,
                      color: isActive ? Colors.green : theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(company.businessName),
                  subtitle: Text('RUC: ${company.ruc}\n${company.address}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Editar'),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/companies/form',
                          arguments: company,
                        ),
                      ),
                      if (!isActive)
                        PopupMenuItem(
                          child: const Text('Seleccionar'),
                          onTap: () => provider.selectCompany(company),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
