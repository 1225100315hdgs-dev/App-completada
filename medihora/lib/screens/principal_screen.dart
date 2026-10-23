import 'package:flutter/material.dart';

import '../core/fechas.dart';
import '../domain/entities/medicamento.dart';
import '../domain/entities/toma_detalle.dart';
import '../domain/value_objects/estados.dart';
import '../presentation/app_scope.dart';
import '../presentation/app_state.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/dashboard.dart';
import '../presentation/widgets/medi_pagina.dart';
import 'rutas.dart';

const List<String> _dias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
const List<String> _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String _fechaLarga(DateTime d) =>
    '${_dias[d.weekday - 1]} ${d.day} de ${_meses[d.month - 1]}';

/// Dashboard del PACIENTE ("Hoy"): el avance del día, la siguiente toma bien visible
/// y las demás tomas con su estado.
class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({super.key});

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  late final AppState _app;

  @override
  void initState() {
    super.initState();
    _app = AppScope.leer(context);
    _app.listoParaAvisos(true);
  }

  @override
  void dispose() {
    _app.listoParaAvisos(false);
    super.dispose();
  }

  /// RN-21: el botón confirma la toma igual que "Ya lo tomé" del aviso.
  Future<void> _confirmar(TomaDetalle d) async {
    final app = AppScope.leer(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await app.confirmarToma(d.toma.id, OrigenConfirmacion.lista);
    if (!ok) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
          const SnackBar(content: Text('¡Muy bien! Toma registrada.')));
  }

  Future<void> _preguntarEliminar(Medicamento m) async {
    final app = AppScope.leer(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.c.tarjeta,
        title: const Text('Eliminar medicina'),
        content: Text('¿Quieres eliminar ${m.nombre} y sus tomas registradas?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.c.rojo),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) await app.eliminarMedicamento(m.id);
  }

  /// Avance del día: un anillo con "tomadas / total" y la racha.
  Widget _resumen(List<TomaDetalle> tomas) {
    final c = context.c;
    final tomadas =
        tomas.where((t) => t.toma.estado == EstadoToma.tomada).length;
    final total = tomas.length;
    final completo = total > 0 && tomadas == total;
    final color = completo ? c.verde : c.primario;
    final dias = _app.racha.dias;

    return MediTarjeta(
      color: completo ? c.verdeSuave : c.primarioSuave,
      bordeColor: color.withAlpha(90),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: CircularProgressIndicator(
                    value: total == 0 ? 0 : tomadas / total,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: c.tarjeta,
                    color: color,
                  ),
                ),
                Text('$tomadas/$total', style: Tema.titulo(tamano: 24)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completo ? '¡Terminaste tus tomas de hoy!' : 'Tomas de hoy',
                  style: Tema.subtitulo(color: completo ? c.verde : null),
                ),
                const SizedBox(height: 2),
                Text(
                  completo
                      ? 'Todo en orden por hoy.'
                      : 'Llevas $tomadas de $total.',
                  style: Tema.cuerpo(color: c.textoSuave, tamano: 15),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.tarjeta,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, color: color, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        dias == 1 ? 'Racha: 1 día' : 'Racha: $dias días',
                        style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w800),
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

  /// La siguiente toma, grande y con el botón para confirmarla.
  Widget _siguiente(TomaDetalle d) {
    final c = context.c;
    final m = d.medicamento;
    final texto = c.sobrePrimario;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: c.primario,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: texto, size: 22),
              const SizedBox(width: 8),
              Text(
                'Siguiente toma',
                style: TextStyle(
                    color: texto, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatoHora12(d.toma.fechaHoraProgramada.hour,
                d.toma.fechaHoraProgramada.minute),
            style: TextStyle(
                color: texto,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                height: 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            m.nombre,
            style: TextStyle(
                color: texto, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          Text(
            m.dosis.texto,
            style: TextStyle(color: texto.withAlpha(230), fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            '${m.horario.descripcionFrecuencia} · ${m.descripcionDuracion}',
            style: TextStyle(color: texto.withAlpha(210), fontSize: 14),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _confirmar(d),
            style: FilledButton.styleFrom(
              backgroundColor: c.tarjeta,
              foregroundColor: c.primarioOscuro,
              minimumSize: const Size.fromHeight(60),
            ),
            icon: const Icon(Icons.check_circle, size: 28),
            label: const Text('Ya lo tomé'),
          ),
        ],
      ),
    );
  }

  Widget _fila(TomaDetalle d) {
    final c = context.c;
    final m = d.medicamento;
    final estado = d.toma.estado;
    final pendiente = estado == EstadoToma.pendiente;

    final Color color;
    final Color fondo;
    final IconData icono;
    switch (estado) {
      case EstadoToma.pendiente:
        color = c.ambar;
        fondo = c.ambarSuave;
        icono = Icons.schedule;
      case EstadoToma.tomada:
        color = c.verde;
        fondo = c.verdeSuave;
        icono = Icons.check;
      case EstadoToma.omitida:
        color = c.rojo;
        fondo = c.rojoSuave;
        icono = Icons.close;
    }

    return MediTarjeta(
      padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
                child: Icon(icono, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatoHora12(
                        d.toma.fechaHoraProgramada.hour,
                        d.toma.fechaHoraProgramada.minute,
                      ),
                      style: Tema.cuerpo(color: c.primarioOscuro, tamano: 16)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(m.nombre, style: Tema.subtitulo(tamano: 21)),
                    Text(m.dosis.texto,
                        style: Tema.cuerpo(color: c.textoSuave, tamano: 15)),
                    Text(
                      '${m.horario.descripcionFrecuencia} · ${m.descripcionDuracion}',
                      style: Tema.cuerpo(color: c.textoSuave, tamano: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Más opciones',
                color: c.tarjeta,
                icon: const Icon(Icons.more_vert, size: 28),
                onSelected: (_) => _preguntarEliminar(m),
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: c.rojo),
                        const SizedBox(width: 10),
                        Text('Eliminar',
                            style: TextStyle(fontSize: 16, color: c.rojo)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: pendiente
                ? BotonExito(
                    texto: 'Ya lo tomé', onPressed: () => _confirmar(d))
                : Align(
                    alignment: Alignment.centerLeft,
                    child: EstadoChip(estado: estado)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final tomas = [...app.tomasDe(app.ahora)]..sort((a, b) {
        final ha = a.medicamento.horario;
        final hb = b.medicamento.horario;
        return (ha.hora * 60 + ha.minuto).compareTo(hb.hora * 60 + hb.minuto);
      });
    final nombre = (app.usuario?.nombre ?? '').trim().split(' ').first;
    final pendientes =
        tomas.where((t) => t.toma.estado == EstadoToma.pendiente).toList();
    final siguiente = pendientes.isEmpty ? null : pendientes.first;
    final otras = tomas
        .where((t) => siguiente == null || t.toma.id != siguiente.toma.id)
        .toList();

    return MediPagina(
      titulo: nombre.isEmpty ? 'Hoy' : 'Hola, $nombre',
      subtitulo: _fechaLarga(app.ahora),
      fab: MediFab(
        texto: 'Agregar medicina',
        onPressed: () => Navigator.of(context).pushNamed(rutaNuevaMedicina),
      ),
      child: tomas.isEmpty
          ? const EstadoVacio(
              icono: Icons.medication_outlined,
              titulo: 'Aún no hay tomas para hoy',
              mensaje: 'Toca «Agregar medicina» para empezar.',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                _resumen(tomas),
                const SizedBox(height: 14),
                if (siguiente != null) ...[
                  _siguiente(siguiente),
                  const SizedBox(height: 18),
                ],
                if (otras.isNotEmpty) ...[
                  Text(
                    siguiente == null ? 'Tomas de hoy' : 'Las demás de hoy',
                    style: Tema.subtitulo(),
                  ),
                  const SizedBox(height: 10),
                  for (final d in otras) ...[
                    _fila(d),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
    );
  }
}
