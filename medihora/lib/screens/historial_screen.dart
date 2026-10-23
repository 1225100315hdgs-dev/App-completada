import 'package:flutter/material.dart';

import '../core/fechas.dart';
import '../domain/value_objects/resumen_diario.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/dashboard.dart';
import '../presentation/widgets/medi_pagina.dart';

const List<String> _letras = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// "Historial": los últimos 7 días en una gráfica, la racha y las tomas del día elegido.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  late DateTime _dia;

  @override
  void initState() {
    super.initState();
    _dia = soloFecha(AppScope.leer(context).ahora);
  }

  String _etiquetaDia(DateTime hoy) {
    if (mismoDia(_dia, hoy)) return 'Hoy';
    if (mismoDia(_dia, sumarDias(hoy, -1))) return 'Ayer';
    return formatoFecha(_dia);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final hoy = soloFecha(app.ahora);
    final dias = app.ultimosDias(7);
    final tomas = app.tomasDe(_dia);
    final resumen = app.resumenDe(_dia);

    return MediPagina(
      titulo: 'Historial',
      subtitulo: 'Cómo van tus tomas',
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          MediTarjeta(
            color: context.c.verdeSuave,
            bordeColor: context.c.verde.withAlpha(120),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.local_fire_department,
                    color: context.c.verde, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    app.racha.dias == 1
                        ? 'Racha: 1 día seguido'
                        : 'Racha: ${app.racha.dias} días seguidos',
                    style: Tema.subtitulo(color: context.c.verde),
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
                Text('Últimos 7 días', style: Tema.subtitulo()),
                const SizedBox(height: 14),
                _Grafica(
                  dias: dias,
                  seleccionado: _dia,
                  onElegir: (d) => setState(() => _dia = soloFecha(d)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              IconButton(
                tooltip: 'Día anterior',
                onPressed: () => setState(() => _dia = sumarDias(_dia, -1)),
                icon: const Icon(Icons.chevron_left, size: 32),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(_etiquetaDia(hoy), style: Tema.titulo(tamano: 24)),
                    Text(
                      resumen.programadas == 0
                          ? 'Sin tomas'
                          : '${resumen.tomadas} de ${resumen.programadas} tomadas',
                      style: Tema.cuerpo(color: context.c.textoSuave),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Día siguiente',
                onPressed: mismoDia(_dia, hoy)
                    ? null
                    : () => setState(() => _dia = sumarDias(_dia, 1)),
                icon: const Icon(Icons.chevron_right, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (tomas.isEmpty)
            const SizedBox(
              height: 220,
              child: EstadoVacio(
                icono: Icons.event_busy,
                titulo: 'No hay tomas este día',
                mensaje: 'Aquí aparecerán tus medicinas con su estado.',
              ),
            )
          else
            for (final d in tomas)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MediTarjeta(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatoHora12(
                                    d.toma.fechaHoraProgramada.hour,
                                    d.toma.fechaHoraProgramada.minute,
                                  ),
                                  style: Tema.subtitulo(
                                      color: context.c.primarioOscuro,
                                      tamano: 18),
                                ),
                                Text(d.medicamento.nombre,
                                    style: Tema.subtitulo(tamano: 20)),
                                Text(
                                  d.medicamento.dosis.texto,
                                  style:
                                      Tema.cuerpo(color: context.c.textoSuave),
                                ),
                              ],
                            ),
                          ),
                          EstadoChip(estado: d.toma.estado),
                        ],
                      ),
                      for (final aviso in app.avisosDeToma(d.toma.id))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.notifications_active,
                                  size: 20, color: context.c.rojo),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(aviso,
                                    style: Tema.cuerpo(
                                        color: context.c.rojo, tamano: 15)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _Grafica extends StatelessWidget {
  const _Grafica(
      {required this.dias, required this.seleccionado, required this.onElegir});

  final List<ResumenDiario> dias;
  final DateTime seleccionado;
  final ValueChanged<DateTime> onElegir;

  Color _color(BuildContext context, ResumenDiario r) {
    if (r.programadas == 0) return context.c.borde;
    if (r.cumplido) return context.c.verde;
    if (r.tieneOmitidas) return context.c.rojo;
    return context.c.primario;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final r in dias)
          Expanded(
            child: Semantics(
              button: true,
              label:
                  '${formatoFecha(r.fecha)}: ${r.tomadas} de ${r.programadas} tomadas',
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onElegir(r.fecha),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Container(
                        height: 12 +
                            80 * (r.programadas == 0 ? 0 : r.porcentaje / 100),
                        width: 26,
                        decoration: BoxDecoration(
                          color: _color(context, r),
                          borderRadius: BorderRadius.circular(8),
                          border: mismoDia(r.fecha, seleccionado)
                              ? Border.all(color: context.c.texto, width: 3)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _letras[r.fecha.weekday - 1],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: mismoDia(r.fecha, seleccionado)
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: context.c.texto,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
