import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/gestion_mora_api.dart';
import '../data/gestion_mora_models.dart';
import 'registrar_gestion_mora_page.dart';

class GestionMoraPage extends StatefulWidget {
  const GestionMoraPage({super.key});

  @override
  State<GestionMoraPage> createState() => _GestionMoraPageState();
}

class _GestionMoraPageState extends State<GestionMoraPage> {
  final _api = GestionMoraApi();
  final _searchController = TextEditingController();
  late Future<CreditosMoraPage> _future;
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

  Future<CreditosMoraPage> _load() async {
    final result = await _api.creditosMora(
      page: _page,
      limit: _limit,
      q: _query,
    );
    if (result.data.isEmpty && result.total > 0 && _page > 1) {
      _page -= 1;
      return _api.creditosMora(page: _page, limit: _limit, q: _query);
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

  Future<void> _openRegistrarGestion(CreditoMora credito) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RegistrarGestionMoraPage(credito: credito),
      ),
    );
    if (created == true && mounted) _reload();
  }

  String _errorMessage(Object? error) {
    if (error is ApiException) {
      if (error.isForbidden) {
        return 'No tiene permiso para ver Gestion Mora. Verifique cobranza.ver.';
      }
      if (error.isUnauthorized) {
        return 'Sesion expirada o no autorizada. Inicie sesion nuevamente.';
      }
      return error.message;
    }
    return 'No se pudieron cargar los creditos en mora.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Mora'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<CreditosMoraPage>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Buscando creditos en mora...');
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: _errorMessage(snapshot.error),
              onRetry: _reload,
            );
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
                    hintText: 'Buscar por referencia, cliente, DUI o cartera',
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
                        ? 'Sin creditos en mora'
                        : 'Sin resultados',
                    message: _query.isEmpty
                        ? 'No hay creditos en mora asignados a esta cartera.'
                        : 'No encontramos creditos en mora con esa busqueda.',
                  )
                else
                  _GestionMoraTable(
                    rows: rows,
                    onGestionar: _openRegistrarGestion,
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

class _PaginationHeader extends StatelessWidget {
  const _PaginationHeader({
    required this.pageData,
    required this.limit,
    required this.onLimitChanged,
  });

  final CreditosMoraPage pageData;
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

  final CreditosMoraPage pageData;
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

class _GestionMoraTable extends StatelessWidget {
  const _GestionMoraTable({required this.rows, required this.onGestionar});

  final List<CreditoMora> rows;
  final ValueChanged<CreditoMora> onGestionar;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 620,
          child: Column(
            children: [
              Container(
                color: const Color(0xFFE7F0FF),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: const Row(
                  children: [
                    _HeaderCell('Codigo', width: 120),
                    _HeaderCell('Nombre', width: 210),
                    _HeaderCell('Mora', width: 140),
                    _HeaderCell('Accion', width: 150, centered: true),
                  ],
                ),
              ),
              ...rows.map(
                (credito) => _CreditoMoraRow(
                  credito: credito,
                  onGestionar: () => onGestionar(credito),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditoMoraRow extends StatelessWidget {
  const _CreditoMoraRow({required this.credito, required this.onGestionar});

  final CreditoMora credito;
  final VoidCallback onGestionar;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.16)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            _BodyCell(credito.referenciaVisual, width: 120),
            _BodyCell(
              credito.cliente.isEmpty ? 'Cliente sin nombre' : credito.cliente,
              width: 210,
            ),
            SizedBox(width: 140, child: _MoraBadge(diasMora: credito.diasMora)),
            SizedBox(
              width: 150,
              child: Center(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(104, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: onGestionar,
                  child: const Text('Gestionar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.text, {
    required this.width,
    this.centered = false,
  });

  final String text;
  final double width;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          text,
          textAlign: centered ? TextAlign.center : TextAlign.left,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.text, {required this.width});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
        ),
      ),
    );
  }
}

class _MoraBadge extends StatelessWidget {
  const _MoraBadge({required this.diasMora});

  final int diasMora;

  @override
  Widget build(BuildContext context) {
    final color = diasMora <= 7
        ? Colors.orange.shade700
        : diasMora <= 30
            ? Colors.deepOrange.shade700
            : Colors.red.shade700;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$diasMora dias',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
