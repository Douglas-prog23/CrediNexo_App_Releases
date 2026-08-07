import 'package:flutter/material.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../../auth/data/auth_api.dart';
import '../../calculadora_cuotas/calculadora_cuotas_page.dart';
import '../../desembolsos_campo/presentation/desembolsos_campo_page.dart';
import '../../gestion_mora/presentation/gestion_mora_page.dart';
import '../../pagos/presentation/pagos_page.dart';
import '../../represtamos/presentation/represtamos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _storage = SecureStorageService();
  AuthUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _storage.readUser();
    if (mounted) setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    final actions = _homeActions(context, _user);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credinexo'),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            tooltip: 'Cerrar sesion',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Hola, ${_user?.username ?? 'usuario'}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '${_user?.empresaNombre ?? 'Empresa'}${_user?.agenciaNombre != null ? ' / ${_user!.agenciaNombre}' : ''}',
            style: const TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 18),
          if (_user == null)
            const Center(child: CircularProgressIndicator())
          else if (actions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No tienes opciones disponibles para tu usuario.'),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.08,
              ),
              itemBuilder: (context, index) =>
                  _HomeOption(action: actions[index]),
            ),
        ],
      ),
    );
  }

  List<_HomeAction> _homeActions(BuildContext context, AuthUser? user) {
    final all = [
      _HomeAction(
        icon: Icons.payments_outlined,
        title: 'Pagos',
        visible: user?.hasPermission('pagos', 'ver') ?? false,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const PagosPage())),
      ),
      _HomeAction(
        icon: Icons.repeat_rounded,
        title: 'Re-prestamos',
        visible: user?.hasAnyPermission([
              ('prestamos_represtamo', 'ver'),
              ('prestamos_represtamo', 'crear'),
            ]) ??
            false,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReprestamosPage()),
        ),
      ),
      _HomeAction(
        icon: Icons.warning_amber_rounded,
        title: 'Gestion Mora',
        visible: user?.hasPermission('cobranza', 'ver') ?? false,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GestionMoraPage()),
        ),
      ),
      _HomeAction(
        icon: Icons.local_atm_rounded,
        title: 'Registrar Desembolso',
        visible: user?.hasAnyPermission([
              ('caja_desembolso', 'ver'),
              ('caja_desembolso', 'crear'),
            ]) ??
            false,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DesembolsosCampoPage()),
        ),
      ),
      _HomeAction(
        icon: Icons.calculate_rounded,
        title: 'Calculadora de Cuotas',
        visible: user != null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CalculadoraCuotasPage()),
        ),
      ),
    ];
    return all.where((action) => action.visible).toList();
  }
}

class _HomeOption extends StatelessWidget {
  const _HomeOption({required this.action});

  final _HomeAction action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFE7F0FF),
                child: Icon(action.icon, color: const Color(0xFF153462)),
              ),
              const SizedBox(height: 12),
              Text(
                action.title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeAction {
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.visible,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool visible;
  final VoidCallback onTap;
}
