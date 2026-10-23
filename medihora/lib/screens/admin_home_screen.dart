import 'package:flutter/material.dart';

import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/dashboard.dart';
import '../presentation/widgets/medi_pagina.dart';

/// Dashboard del ADMINISTRADOR: resumen de toda la operación y acceso a las cuentas.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Widget _fila(Widget a, Widget b) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final nombre = app.usuario?.nombre ?? 'admin';
    final r = app.resumenAdmin;

    return MediPagina(
      titulo: 'Hola, $nombre',
      subtitulo: 'Administrador',
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          if (r.alertasSinAtender > 0) ...[
            MediTarjeta(
              color: context.c.ambarSuave,
              bordeColor: context.c.ambar.withAlpha(120),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: context.c.ambar, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      r.alertasSinAtender == 1
                          ? 'Hay 1 alerta que ningún cuidador ha atendido'
                          : 'Hay ${r.alertasSinAtender} alertas que ningún cuidador ha atendido',
                      style: Tema.subtitulo(tamano: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          _fila(
            MediStat(icono: Icons.group, valor: r.usuarios, etiqueta: 'Usuarios'),
            MediStat(
              icono: Icons.elderly,
              valor: r.pacientes,
              etiqueta: 'Pacientes',
              color: context.c.verde,
              fondo: context.c.verdeSuave,
            ),
          ),
          const SizedBox(height: 12),
          _fila(
            MediStat(
              icono: Icons.volunteer_activism,
              valor: r.cuidadores,
              etiqueta: 'Cuidadores',
            ),
            MediStat(
              icono: Icons.medication,
              valor: r.medicinas,
              etiqueta: 'Medicinas registradas',
              color: context.c.verde,
              fondo: context.c.verdeSuave,
            ),
          ),
          const SizedBox(height: 12),
          _fila(
            MediStat(
              icono: Icons.cancel,
              valor: r.tomasOmitidas,
              etiqueta: 'Tomas omitidas',
              color: context.c.rojo,
              fondo: context.c.rojoSuave,
            ),
            MediStat(
              icono: Icons.notifications_active,
              valor: r.alertasSinAtender,
              etiqueta: 'Alertas sin atender',
              color: r.alertasSinAtender > 0 ? context.c.ambar : context.c.verde,
              fondo: r.alertasSinAtender > 0 ? context.c.ambarSuave : context.c.verdeSuave,
            ),
          ),
        ],
      ),
    );
  }
}
