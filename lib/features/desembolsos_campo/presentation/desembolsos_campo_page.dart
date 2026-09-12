import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/money_format.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../data/desembolsos_campo_api.dart';
import '../data/desembolsos_campo_models.dart';
import 'registrar_entrega_desembolso_page.dart';

class DesembolsosCampoPage extends StatefulWidget {
  const DesembolsosCampoPage({super.key});

  @override
  State<DesembolsosCampoPage> createState() => _DesembolsosCampoPageState();
}

class _DesembolsosCampoPageState extends State<DesembolsosCampoPage> {
  final _api = DesembolsosCampoApi();
  final _searchController = TextEditingController();
  late Future<DesembolsosCampoPageData> _future;
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

  Future<DesembolsosCampoPageData> _load() async {
    final result =
        await _api.getDisponibles(page: _page, limit: _limit, q: _query);
    if (result.data.isEmpty && result.total > 0 && _page > 1) {
      _page -= 1;
      final retry =
          await _api.getDisponibles(page: _page, limit: _limit, q: _query);
      return DesembolsosCampoPageData.fromApi(retry);
    }
    return DesembolsosCampoPageData.fromApi(result);
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

  Future<void> _openForm(DesembolsoCampoDisponible item) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => RegistrarEntregaDesembolsoPage(item: item)),
    );
    if (saved == true && mounted) {
      _page = 1;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega registrada correctamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Desembolso'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<DesembolsosCampoPageData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(
                message: 'Buscando desembolsos disponibles...');
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'No se pudieron cargar los desembolsos disponibles.';
            return ErrorView(message: message, onRetry: _reload);
          }

          final pageData = snapshot.data!;
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
                    hintText:
                        'Buscar por cliente, DUI, solicitud o credito origen',
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
                          onPressed: _buscar),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                          label: 'Limpiar',
                          outlined: true,
                          onPressed: _limpiar),
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
                if (pageData.data.isEmpty)
                  EmptyView(
                    title: _query.isEmpty
                        ? 'Sin desembolsos disponibles'
                        : 'Sin resultados',
                    message: _query.isEmpty
                        ? 'No hay desembolsos habilitados por Caja para tu usuario.'
                        : 'No encontramos solicitudes disponibles con esa busqueda.',
                  )
                else
                  _DesembolsosTable(
                    rows: pageData.data,
                    onRegistrar: _openForm,
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

class DesembolsosCampoPageData {
  const DesembolsosCampoPageData({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<DesembolsoCampoDisponible> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory DesembolsosCampoPageData.fromApi(DesembolsosCampoPageResult page) {
    return DesembolsosCampoPageData(
      data: page.data,
      total: page.total,
      page: page.page,
      limit: page.limit,
      totalPages: page.totalPages,
    );
  }
}

class _PaginationHeader extends StatelessWidget {
  const _PaginationHeader(
      {required this.pageData,
      required this.limit,
      required this.onLimitChanged});

  final DesembolsosCampoPageData pageData;
  final int limit;
  final ValueChanged<int> onLimitChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Mostrando ${pageData.data.length} de ${pageData.total} registros',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
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
  const _PaginationFooter(
      {required this.pageData, required this.onPrevious, required this.onNext});

  final DesembolsosCampoPageData pageData;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: AppButton(
                label: 'Anterior', outlined: true, onPressed: onPrevious)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('Pagina ${pageData.page} de ${pageData.totalPages}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        Expanded(
            child: AppButton(
                label: 'Siguiente', outlined: true, onPressed: onNext)),
      ],
    );
  }
}

class _DesembolsosTable extends StatelessWidget {
  const _DesembolsosTable({required this.rows, required this.onRegistrar});

  final List<DesembolsoCampoDisponible> rows;
  final ValueChanged<DesembolsoCampoDisponible> onRegistrar;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 590,
          child: Column(
            children: [
              Container(
                color: const Color(0xFFE7F0FF),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: const Row(
                  children: [
                    _HeaderCell('Nombre', width: 210),
                    _HeaderCell('Monto', width: 110, alignRight: true),
                    _HeaderCell('Estado', width: 140),
                    _HeaderCell('Accion', width: 130, centered: true),
                  ],
                ),
              ),
              ...rows.map(
                (item) => _DesembolsoRow(
                  item: item,
                  onRegistrar: () => onRegistrar(item),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesembolsoRow extends StatelessWidget {
  const _DesembolsoRow({required this.item, required this.onRegistrar});

  final DesembolsoCampoDisponible item;
  final VoidCallback onRegistrar;

  @override
  Widget build(BuildContext context) {
    final monto = item.liquidoAEntregar > 0
        ? item.liquidoAEntregar
        : item.montoADesembolsar > 0
            ? item.montoADesembolsar
            : item.montoAprobado;
    final estado = item.estadoEntregaCampo ?? item.estado ?? 'PENDIENTE';
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
            _BodyCell(
              item.clienteVisual.isEmpty
                  ? 'Cliente sin nombre'
                  : item.clienteVisual,
              width: 210,
            ),
            _BodyCell(moneyFormat(monto), width: 110, alignRight: true),
            SizedBox(
              width: 140,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _EstadoChip(text: estado),
                  _TipoChip(text: item.tipoLabel),
                ],
              ),
            ),
            SizedBox(
              width: 130,
              child: Center(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(98, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: onRegistrar,
                  child: const Text('Registrar'),
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

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final normalized = text.toUpperCase();
    final color = normalized.contains('PEND')
        ? Colors.orange.shade700
        : Colors.green.shade700;
    return _MiniChip(text: text, color: color);
  }
}

class _TipoChip extends StatelessWidget {
  const _TipoChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = text.toUpperCase() == 'REPRESTAMO'
        ? Colors.blue.shade700
        : Colors.indigo.shade700;
    return _MiniChip(text: text, color: color);
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11),
      ),
    );
  }
}
