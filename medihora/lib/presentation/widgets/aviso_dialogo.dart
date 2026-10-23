import 'package:flutter/material.dart';

import '../../core/fechas.dart';
import '../../domain/entities/toma_detalle.dart';
import '../../domain/value_objects/estados.dart';
import '../../screens/rutas.dart';
import '../app_scope.dart';
import '../tema.dart';
import 'componentes.dart';

/// Aviso "Es hora de tomar tu medicamento" con las dos acciones (RN-11 y RN-12).
class AvisoDialogo extends StatelessWidget {
  const AvisoDialogo({super.key, required this.aviso});

  final TomaDetalle aviso;

  Future<void> _yaLoTome(BuildContext context) async {
    final app = AppScope.leer(context);
    final nav = Navigator.of(context);
    final ok =
        await app.confirmarToma(aviso.toma.id, OrigenConfirmacion.notificacion);
    nav.pop();
    // "Confirmación": pantalla que celebra la toma y muestra la racha.
    if (ok) nav.pushNamed(rutaConfirmacion);
  }

  Future<void> _posponer(BuildContext context) async {
    final app = AppScope.leer(context);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await app.posponerToma(aviso.toma.id);
    nav.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Te avisaremos de nuevo en 10 minutos.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = aviso.medicamento;
    return AlertDialog(
      backgroundColor: context.c.tarjeta,
      title: const Text('Es hora de tomar tu medicamento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(m.nombre,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(m.dosis.texto, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            formatoHora12(aviso.toma.fechaHoraProgramada.hour,
                aviso.toma.fechaHoraProgramada.minute),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            '${m.horario.descripcionFrecuencia} · ${m.descripcionDuracion}',
            style: Tema.cuerpo(color: context.c.textoSuave, tamano: 14),
          ),
          const SizedBox(height: 20),
          BotonExito(texto: 'Ya lo tomé', onPressed: () => _yaLoTome(context)),
          const SizedBox(height: 10),
          BotonSecundario(
            texto: 'Posponer 10 minutos',
            icono: Icons.snooze,
            onPressed: () => _posponer(context),
          ),
        ],
      ),
    );
  }
}
