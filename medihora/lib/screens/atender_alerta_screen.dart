import 'package:flutter/material.dart';

import '../core/fechas.dart';
import '../domain/entities/alerta_detalle.dart';
import '../domain/value_objects/estados.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/medi_pagina.dart';

/// Detalle de una alerta para el CUIDADOR, con su formulario: registrar cómo
/// se comunicó con la persona (llamada, mensaje o visita) y una nota.
/// Recibe como argumento de la ruta el id de la alerta.
class AtenderAlertaScreen extends StatefulWidget {
  const AtenderAlertaScreen({super.key});

  @override
  State<AtenderAlertaScreen> createState() => _AtenderAlertaScreenState();
}

class _AtenderAlertaScreenState extends State<AtenderAlertaScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _nota = TextEditingController();
  MedioContacto _medio = MedioContacto.llamada;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  Future<void> _guardar(String alertaId) async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final app = AppScope.leer(context);
    final nav = Navigator.of(context);
    final mensajes = ScaffoldMessenger.of(context);
    setState(() {
      _guardando = true;
      _error = null;
    });
    final error = await app.registrarAtencion(alertaId, _medio, _nota.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _guardando = false;
        _error = error;
      });
      return;
    }
    nav.pop();
    mensajes
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Atención registrada.')));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final id = ModalRoute.of(context)?.settings.arguments;
    final d = id is String ? app.alertaVisible(id) : null;

    return MediPagina(
      titulo: 'Atender alerta',
      subtitulo: d == null ? null : d.paciente.nombre,
      accionSuperior: const BotonVolver(),
      child: d == null
          ? Center(
              child: Text('No encontramos esa alerta.',
                  style: Tema.cuerpo(color: context.c.textoSuave)),
            )
          : ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                _Resumen(d: d),
                const SizedBox(height: 14),
                if (d.alerta.atendida)
                  _YaAtendida(d: d)
                else
                  MediTarjeta(
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Registrar atención', style: Tema.subtitulo()),
                          const SizedBox(height: 4),
                          Text(
                            '¿Cómo te comunicaste con ${d.paciente.nombre}?',
                            style: Tema.cuerpo(color: context.c.textoSuave),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final m in MedioContacto.values)
                                ChoiceChip(
                                  label: Text(m.etiqueta,
                                      style: const TextStyle(fontSize: 17)),
                                  selected: _medio == m,
                                  onSelected: (_) => setState(() => _medio = m),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          MediCampo(
                            etiqueta: 'Nota',
                            controller: _nota,
                            hint: 'Ej. Hablé con ella y ya se tomó la medicina',
                            icono: Icons.edit_note,
                            maxLineas: 3,
                            validator: (v) => (v == null || v.trim().length < 3)
                                ? 'Escribe una nota breve de lo que hablaron.'
                                : null,
                          ),
                          if (_error != null) MensajeError(_error!),
                          BotonPrimario(
                            texto: _guardando
                                ? 'Guardando...'
                                : 'Registrar atención',
                            icono: Icons.check,
                            onPressed:
                                _guardando ? null : () => _guardar(d.alerta.id),
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

class _Resumen extends StatelessWidget {
  const _Resumen({required this.d});

  final AlertaDetalle d;

  @override
  Widget build(BuildContext context) {
    final aviso = d.alerta.fechaHoraEnvio;
    return MediTarjeta(
      color: d.alerta.atendida ? context.c.tarjeta : context.c.rojoSuave,
      bordeColor: d.alerta.atendida ? null : context.c.rojo.withAlpha(120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${d.paciente.nombre} no confirmó su medicina',
            style: Tema.subtitulo(tamano: 20),
          ),
          const SizedBox(height: 10),
          _Linea(Icons.medication_outlined,
              '${d.medicamento.nombre} · ${d.medicamento.dosis.texto}'),
          _Linea(
            Icons.schedule,
            '${formatoFecha(d.toma.fechaHoraProgramada)} · '
            '${formatoHora12(d.toma.fechaHoraProgramada.hour, d.toma.fechaHoraProgramada.minute)}',
          ),
          _Linea(
            Icons.notifications_active_outlined,
            'Se te avisó a las ${formatoHora12(aviso.hour, aviso.minute)} '
            'como ${d.cuidador.parentesco.valor.toLowerCase()}',
          ),
        ],
      ),
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea(this.icono, this.texto);

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 22, color: context.c.primario),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: Tema.cuerpo())),
        ],
      ),
    );
  }
}

class _YaAtendida extends StatelessWidget {
  const _YaAtendida({required this.d});

  final AlertaDetalle d;

  @override
  Widget build(BuildContext context) {
    final cuando = d.alerta.atendidaEn;
    return MediTarjeta(
      color: context.c.verdeSuave,
      bordeColor: context.c.verde.withAlpha(120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: context.c.verde, size: 30),
              const SizedBox(width: 8),
              Text('Alerta atendida',
                  style: Tema.subtitulo(color: context.c.verde)),
            ],
          ),
          const SizedBox(height: 10),
          if (d.alerta.medio != null)
            Text('Medio: ${d.alerta.medio!.etiqueta}', style: Tema.cuerpo()),
          if (cuando != null)
            Text(
              '${formatoFecha(cuando)} · ${formatoHora12(cuando.hour, cuando.minute)}',
              style: Tema.cuerpo(color: context.c.textoSuave, tamano: 15),
            ),
          if (d.alerta.nota != null) ...[
            const SizedBox(height: 8),
            Text('“${d.alerta.nota}”', style: Tema.cuerpo()),
          ],
        ],
      ),
    );
  }
}
