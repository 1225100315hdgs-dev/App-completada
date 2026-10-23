import 'package:flutter/material.dart';

import '../presentation/widgets/shell_navegacion.dart';
import 'admin_home_screen.dart';
import 'admin_usuarios_screen.dart';
import 'configuracion_screen.dart';
import 'cuidador_alertas_screen.dart';
import 'cuidador_home_screen.dart';
import 'cuidadores_screen.dart';
import 'historial_screen.dart';
import 'principal_screen.dart';

/// Pestañas del PACIENTE: Hoy, Historial, Cuidadores y Ajustes.
class PacienteShell extends StatelessWidget {
  const PacienteShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShellNavegacion(
      destinos: [
        DestinoShell(
          icono: Icons.medication_outlined,
          iconoActivo: Icons.medication,
          etiqueta: 'Hoy',
          pantalla: PrincipalScreen(),
        ),
        DestinoShell(
          icono: Icons.bar_chart_outlined,
          iconoActivo: Icons.bar_chart,
          etiqueta: 'Historial',
          pantalla: HistorialScreen(),
        ),
        DestinoShell(
          icono: Icons.people_outline,
          iconoActivo: Icons.people,
          etiqueta: 'Cuidadores',
          pantalla: CuidadoresScreen(),
        ),
        DestinoShell(
          icono: Icons.settings_outlined,
          iconoActivo: Icons.settings,
          etiqueta: 'Ajustes',
          pantalla: ConfiguracionScreen(),
        ),
      ],
    );
  }
}

/// Pestañas del CUIDADOR: Inicio, Alertas y Ajustes.
class CuidadorShell extends StatelessWidget {
  const CuidadorShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShellNavegacion(
      destinos: [
        DestinoShell(
          icono: Icons.home_outlined,
          iconoActivo: Icons.home,
          etiqueta: 'Inicio',
          pantalla: CuidadorHomeScreen(),
        ),
        DestinoShell(
          icono: Icons.notifications_none,
          iconoActivo: Icons.notifications,
          etiqueta: 'Alertas',
          pantalla: CuidadorAlertasScreen(),
        ),
        DestinoShell(
          icono: Icons.settings_outlined,
          iconoActivo: Icons.settings,
          etiqueta: 'Ajustes',
          pantalla: ConfiguracionScreen(),
        ),
      ],
    );
  }
}

/// Pestañas del ADMINISTRADOR: Resumen, Usuarios y Ajustes.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShellNavegacion(
      destinos: [
        DestinoShell(
          icono: Icons.dashboard_outlined,
          iconoActivo: Icons.dashboard,
          etiqueta: 'Resumen',
          pantalla: AdminHomeScreen(),
        ),
        DestinoShell(
          icono: Icons.group_outlined,
          iconoActivo: Icons.group,
          etiqueta: 'Usuarios',
          pantalla: AdminUsuariosScreen(),
        ),
        DestinoShell(
          icono: Icons.settings_outlined,
          iconoActivo: Icons.settings,
          etiqueta: 'Ajustes',
          pantalla: ConfiguracionScreen(),
        ),
      ],
    );
  }
}
