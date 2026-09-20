import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/money_format.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../pagos/data/pagos_models.dart';
import '../data/gestion_creditos_api.dart';
import 'gestion_credito_detail_page.dart';

class GestionCreditosPage extends StatefulWidget {
  const GestionCreditosPage({super.key});

  @override
  State<GestionCreditosPage> createState() => _GestionCreditosPageState();
}

class _GestionCreditosPageState extends State<GestionCreditosPage> {
  final _api = GestionCreditosApi();
  final _searchController = TextEditingController();
  late Future<CreditosDisponiblesPage> _future;
  int _page = 1;
  int _limit = 10;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<CreditosDisponiblesPage> _load() async {
    final result = await _api.creditos(page: _page, limit: _limit, q: _query);
    if (result.data.isEmpty && result.total > 0 && _page > 1) {
      _page -= 1;
      return _api.creditos(page: _page, limit: _limit, q: _query);
    }
    return result;
  }

  void _reload() {
    setState(() => _future = _load());
  }

  void _buscar() {
    _query = _searchController.text.trim();
    _page = 1;
    _reload();
  }

  void _limpiar() {
    _searchController.clear();
    _query = '';
    _page = 1;
    _reload();
  }

  Future<void> _openDetail(CreditoDisponible credito) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GestionCreditoDetailPage(credito: credito),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Creditos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<CreditosDisponiblesPage>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Cargando creditos asignados...');
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'No se pudieron cargar los creditos.';
            return ErrorView(message: message, onRetry: _reload);
          }

          final pageData = snapshot.data!;
          final rows = pageData.data;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Buscar por referencia, cliente o cartera',
                  ),
                  onSubmitted: (_) => _buscar(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Buscar',
                        icon: Icons.search_rounded,
                        onPressed: _buscar,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Limpiar',
                        outlined: true,
                        onPressed: _limpiar,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _PaginationHeader(
                  pageData: pageData,
                  limit: _limit,
                  onLimitChanged: (next) {
                    _limit = next;
                    _page = 1;
                    _reload();
                  },
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  EmptyView(
                    title: _query.isEmpty
                        ? 'Sin creditos asignados'
                        : 'Sin resultados',
                    message: _query.isEmpty
                        ? 'No hay creditos disponibles para consultar.'
                        : 'No encontramos creditos con esa busqueda.',
                  )
                else
                  ...rows.map(
                    (credito) => _CreditoGestionCard(
                      credito: credito,
                      onTap: () => _openDetail(credito),
                    ),
                  ),
                const SizedBox(height: 12),
                _PaginationFooter(
                  pageData: pageData,
                  onPrevious: pageData.page <= 1
                      ? null
                      : () {
                          _page = pageData.page - 1;
                          _reload();
                        },
                  onNext: pageData.page >= pageData.totalPages
                      ? null
                      : () {
                          _page = pageData.page + 1;
                          _reload();
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CreditoGestionCard extends StatelessWidget {
  const _CreditoGestionCard({required this.credito, required this.onTap});

  final CreditoDisponible credito;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cliente = credito.cliente.nombreCompleto.trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          title: Text(
            cliente.isEmpty ? 'Cliente sin nombre' : cliente,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _InfoPill(
                  icon: Icons.numbers_rounded,
                  text: credito.referenciaVisual,
                ),
                _InfoPill(
                  icon: Icons.attach_money_rounded,
                  text: moneyFormat(credito.monto),
                ),
                if ((credito.carteraNombre ?? '').isNotEmpty)
                  _InfoPill(
                    icon: Icons.folder_shared_rounded,
                    text: credito.carteraNombre!,
                  ),
                _EstadoBadge(estado: credito.estado),
              ],
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}

class _PaginationHeader extends StatelessWidget {
  const _PaginationHeader({
    required this.pageData,
    required this.limit,
    required this.onLimitChanged,
  });

  final CreditosDisponiblesPage pageData;
  final int limit;
  final ValueChanged<int> onLimitChanged;

  @override
  Widget build(BuildContext context) {
    final showing = pageData.data.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Mostrando $showing de ${pageData.total} registros',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: limit,
              underline: const SizedBox.shrink(),
              items: const [10, 25, 50]
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text('$value')))
                  .toList(),
              onChanged: (value) {
                if (value != null) onLimitChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.pageData,
    required this.onPrevious,
    required this.onNext,
  });

  final CreditosDisponiblesPage pageData;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Anterior',
            outlined: true,
            onPressed: onPrevious,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Pagina ${pageData.page} de ${pageData.totalPages}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: AppButton(
            label: 'Siguiente',
            outlined: true,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blueGrey.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.blueGrey.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final normalized = estado.toLowerCase();
    final color = normalized == 'vigente'
        ? Colors.green.shade700
        : normalized == 'vencido'
            ? Colors.orange.shade800
            : Colors.blueGrey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        estado.isEmpty ? 'Sin estado' : estado,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
