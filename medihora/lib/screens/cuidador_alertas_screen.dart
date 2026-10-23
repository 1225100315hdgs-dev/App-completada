import 'package:flutter/material.dart';

import '../core/fechas.dart';
import '../domain/entities/alerta_detalle.dart';
import '../domain/value_objects/estados.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/dashboard.dart';
import '../presentation/widgets/medi_pagina.dart';
import 'rutas.dart';

enum _Filtro { todas, sinAtender, atendidas }

/// Lista principal del CUIDADOR: las alertas que recibió, con filtro y estado vacío.
class CuidadorAlertasScreen extends StatefulWidget {
  const CuidadorAlertasScreen({super.key});

  @override
  State<CuidadorAlertasScreen> createState() => _CuidadorAlertasScreenState();
}

class _CuidadorAlertasScreenState extends State<CuidadorAlertasScreen> {
  _Filtro _filtro = _Filtro.todas;

  List<AlertaDetalle> _filtrar(List<AlertaDetalle> alertas) {
    switch (_filtro) {
      case _Filtro.todas:
        return alertas;
      case _Filtro.sinAtender:
        return alertas.where((a) => !a.alerta.atendida).toList();
      case _Filtro.atendidas:
        return alertas.where((a) => a.alerta.atendida).toList();
    }
  }

  String _nombre(_Filtro f) {
    switch (f) {
      case _Filtro.todas:
        return 'Todas';
      case _Filtro.sinAtender:
        return 'Sin atender';
      case _Filtro.atendidas:
        return 'Atendidas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final todas = app.alertasRecibidas;
    final lista = _filtrar(todas);

    return MediPagina(
      titulo: 'Alertas',
      subtitulo: todas.length == 1 ? '1 alerta' : '${todas.length} alertas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final f in _Filtro.values)
                ChoiceChip(
                  label: Text(_nombre(f), style: const TextStyle(fontSize: 16)),
                  selected: _filtro == f,
                  onSelected: (_) => setState(() => _filtro = f),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: lista.isEmpty
                ? EstadoVacio(
                    icono: Icons.notifications_none,
                    titulo: todas.isEmpty
                        ? 'Aún no hay alertas'
                        : 'No hay alertas en esta lista',
                    mensaje: todas.isEmpty
                        ? 'Cuando alguien olvide una toma, te avisaremos aquí.'
                        : null,
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      for (final d in lista)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.of(context).pushNamed(
                                rutaAtenderAlerta,
                                arguments: d.alerta.id),
                            child: MediTarjeta(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.paciente.nombre,
                                      style: Tema.subtitulo(tamano: 20)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'No confirmó ${d.medicamento.nombre} (${d.medicamento.dosis.texto})',
                                    style: Tema.cuerpo(),
                                  ),
                                  Text(
                                    '${formatoFecha(d.toma.fechaHoraProgramada)} · '
                                    '${formatoHora12(d.toma.fechaHoraProgramada.hour, d.toma.fechaHoraProgramada.minute)}',
                                    style: Tema.cuerpo(
                                        color: context.c.textoSuave,
                                        tamano: 15),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _Insignia(atendida: d.alerta.atendida),
                                      if (d.alerta.medio != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          d.alerta.medio!.etiqueta,
                                          style: Tema.cuerpo(
                                              color: context.c.textoSuave,
                                              tamano: 15),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
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

class _Insignia extends StatelessWidget {
  const _Insignia({required this.atendida});

  final bool atendida;

  @override
  Widget build(BuildContext context) {
    final color = atendida ? context.c.verde : context.c.rojo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: atendida ? context.c.verdeSuave : context.c.rojoSuave,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(atendida ? Icons.check_circle : Icons.notifications_active,
              size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            atendida ? 'Atendida' : 'Sin atender',
            style: TextStyle(
                color: color, fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
