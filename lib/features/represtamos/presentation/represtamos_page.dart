import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/money_format.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/represtamos_api.dart';
import '../data/represtamos_models.dart';
import 'represtamo_form_page.dart';

class ReprestamosPage extends StatefulWidget {
  const ReprestamosPage({super.key});

  @override
  State<ReprestamosPage> createState() => _ReprestamosPageState();
}

class _ReprestamosPageState extends State<ReprestamosPage> {
  final _api = ReprestamosApi();
  final _searchController = TextEditingController();
  late Future<ReprestamosDisponiblesPage> _future;
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

  Future<ReprestamosDisponiblesPage> _load() async {
    final result = await _api.creditosDisponibles(
      page: _page,
      limit: _limit,
      q: _query,
    );
    if (result.data.isEmpty && result.total > 0 && _page > 1) {
      _page -= 1;
      return _api.creditosDisponibles(page: _page, limit: _limit, q: _query);
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

  Future<void> _openForm(CreditoReprestamoDisponible credito) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReprestamoFormPage(creditoId: credito.creditoId),
      ),
    );
    if (created == true && mounted) {
      _page = 1;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solicitud de re-prestamo creada correctamente. Queda pendiente de resolucion.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Re-prestamos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<ReprestamosDisponiblesPage>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(
                message: 'Buscando creditos disponibles...');
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'No se pudieron cargar los creditos disponibles.';
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
                        ? 'Sin creditos disponibles'
                        : 'Sin resultados',
                    message: _query.isEmpty
                        ? 'No hay creditos aptos para re-prestamo asignados a este usuario.'
                        : 'No encontramos creditos disponibles con esa busqueda.',
                  )
                else
                  _ReprestamosTable(
                    rows: rows,
                    onSolicitar: _openForm,
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

  final ReprestamosDisponiblesPage pageData;
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

  final ReprestamosDisponiblesPage pageData;
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

class _ReprestamosTable extends StatelessWidget {
  const _ReprestamosTable({required this.rows, required this.onSolicitar});

  final List<CreditoReprestamoDisponible> rows;
  final ValueChanged<CreditoReprestamoDisponible> onSolicitar;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 650,
          child: Column(
            children: [
              Container(
                color: const Color(0xFFE7F0FF),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: const Row(
                  children: [
                    _HeaderCell('Codigo', width: 120),
                    _HeaderCell('Nombre', width: 190),
                    _HeaderCell('Tipo', width: 110),
                    _HeaderCell('Monto', width: 110, alignRight: true),
                    _HeaderCell('Accion', width: 120, centered: true),
                  ],
                ),
              ),
              ...rows.map(
                (credito) => _ReprestamoRow(
                  credito: credito,
                  onSolicitar: () => onSolicitar(credito),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReprestamoRow extends StatelessWidget {
  const _ReprestamoRow({required this.credito, required this.onSolicitar});

  final CreditoReprestamoDisponible credito;
  final VoidCallback onSolicitar;

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
              width: 190,
            ),
            SizedBox(width: 110, child: _TipoChip(text: credito.tipoVisual)),
            _BodyCell(
              moneyFormat(credito.monto),
              width: 110,
              alignRight: true,
            ),
            SizedBox(
              width: 120,
              child: Center(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(92, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: onSolicitar,
                  child: const Text('Solicitar'),
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
    this.alignRight = false,
    this.centered = false,
  });

  final String text;
  final double width;
  final bool alignRight;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          text,
          textAlign: centered
              ? TextAlign.center
              : alignRight
                  ? TextAlign.right
                  : TextAlign.left,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(
    this.text, {
    required this.width,
    this.alignRight = false,
  });

  final String text;
  final double width;
  final bool alignRight;

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
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
        ),
      ),
    );
  }
}

class _TipoChip extends StatelessWidget {
  const _TipoChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF153462),
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
