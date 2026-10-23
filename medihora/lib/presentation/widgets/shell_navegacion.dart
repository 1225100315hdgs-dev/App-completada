import 'package:flutter/material.dart';

/// Una pestaña de la barra inferior: su icono, su nombre y la pantalla que muestra.
class DestinoShell {
  const DestinoShell({
    required this.icono,
    required this.iconoActivo,
    required this.etiqueta,
    required this.pantalla,
  });

  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;
  final Widget pantalla;
}

/// Barra de navegación inferior con una pestaña por sección. Todas las pantallas
/// se mantienen vivas (IndexedStack): no pierden su estado al cambiar de pestaña.
class ShellNavegacion extends StatefulWidget {
  const ShellNavegacion({super.key, required this.destinos});

  final List<DestinoShell> destinos;

  @override
  State<ShellNavegacion> createState() => _ShellNavegacionState();
}

class _ShellNavegacionState extends State<ShellNavegacion> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: [for (final d in widget.destinos) d.pantalla],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: [
          for (final d in widget.destinos)
            NavigationDestination(
              icon: Icon(d.icono),
              selectedIcon: Icon(d.iconoActivo),
              label: d.etiqueta,
            ),
        ],
      ),
    );
  }
}
