import 'package:flutter/material.dart';

import '../core/fechas.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/dashboard.dart';
import '../presentation/widgets/medi_pagina.dart';
import 'rutas.dart';

/// Dashboard del CUIDADOR: las alertas de las personas a su cuidado.
class CuidadorHomeScreen extends StatefulWidget {
  const CuidadorHomeScreen({super.key});

  @override
  State<CuidadorHomeScreen> createState() => _CuidadorHomeScreenState();
}

class _CuidadorHomeScreenState extends State<CuidadorHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final nombre = app.usuario?.nombre ?? 'cuidador';
    final alertas = app.alertasRecibidas;
    final pendientes = alertas.where((a) => !a.alerta.atendida).toList();
    final atendidas = alertas.length - pendientes.length;
    final pacientes = app.pacientesACargo;

    return MediPagina(
      titulo: 'Hola, $nombre',
      subtitulo: 'Cuidador',
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          if (pendientes.isEmpty)
            MediTarjeta(
              color: context.c.verdeSuave,
              bordeColor: context.c.verde.withAlpha(120),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: context.c.verde, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No tienes alertas pendientes',
                      style: Tema.subtitulo(color: context.c.verde),
                    ),
                  ),
                ],
              ),
            )
          else
            MediTarjeta(
              color: context.c.rojoSuave,
              bordeColor: context.c.rojo.withAlpha(120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active,
                          color: context.c.rojo, size: 30),
                      const SizedBox(width: 8),
                      Text('Alerta sin atender',
                          style: Tema.subtitulo(color: context.c.rojo)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${pendientes.first.paciente.nombre} no confirmó '
                    '${pendientes.first.medicamento.nombre}',
                    style: Tema.subtitulo(tamano: 20),
                  ),
                  Text(
                    '${formatoFecha(pendientes.first.toma.fechaHoraProgramada)} · '
                    '${formatoHora12(pendientes.first.toma.fechaHoraProgramada.hour, pendientes.first.toma.fechaHoraProgramada.minute)}',
                    style: Tema.cuerpo(color: context.c.textoSuave),
                  ),
                  const SizedBox(height: 14),
                  BotonPrimario(
                    texto: 'Atender alerta',
                    icono: Icons.arrow_forward,
                    onPressed: () => Navigator.of(context).pushNamed(
                        rutaAtenderAlerta,
                        arguments: pendientes.first.alerta.id),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: MediStat(
                    icono: Icons.pending_actions,
                    valor: pendientes.length,
                    etiqueta: 'Sin atender',
                    color: context.c.rojo,
                    fondo: context.c.rojoSuave,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MediStat(
                    icono: Icons.check_circle,
                    valor: atendidas,
                    etiqueta: 'Atendidas',
                    color: context.c.verde,
                    fondo: context.c.verdeSuave,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          MediTarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personas a mi cuidado', style: Tema.subtitulo()),
                const SizedBox(height: 10),
                if (pacientes.isEmpty)
                  Text(
                    'Todavía nadie te agregó como cuidador. Pide que usen el correo de '
                    'tu cuenta al agregarte.',
                    style: Tema.cuerpo(color: context.c.textoSuave),
                  )
                else
                  for (final p in pacientes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: context.c.primarioSuave,
                            child: Text(
                              p.nombre.isEmpty
                                  ? '?'
                                  : p.nombre[0].toUpperCase(),
                              style: Tema.subtitulo(
                                  color: context.c.primarioOscuro),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('${p.nombre} · ${p.edad} años',
                                style: Tema.cuerpo()),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
