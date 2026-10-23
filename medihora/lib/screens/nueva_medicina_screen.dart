import 'package:flutter/material.dart';

import '../core/fechas.dart';
import '../domain/builders/medicamento_builder.dart';
import '../domain/value_objects/dosis.dart';
import '../domain/value_objects/horario.dart';
import '../presentation/app_scope.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/medi_pagina.dart';

/// "Nueva Medicina": nombre, dosis, horario e información adicional (opcional).
/// Usa el patrón Builder para armar el medicamento.
class NuevaMedicinaScreen extends StatefulWidget {
  const NuevaMedicinaScreen({super.key});

  @override
  State<NuevaMedicinaScreen> createState() => _NuevaMedicinaScreenState();
}

class _NuevaMedicinaScreenState extends State<NuevaMedicinaScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _dosis = TextEditingController();
  final TextEditingController _horario = TextEditingController();
  final TextEditingController _duracion = TextEditingController();
  final TextEditingController _info = TextEditingController();
  TimeOfDay? _hora;
  int _intervaloHoras = 24;
  bool _tratamientoContinuo = false;
  String? _error;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _dosis.dispose();
    _horario.dispose();
    _duracion.dispose();
    _info.dispose();
    super.dispose();
  }

  Future<void> _elegirHora() async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: _hora ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (elegida == null || !mounted) return;
    setState(() {
      _hora = elegida;
      _horario.text = Horario(
        hora: elegida.hour,
        minuto: elegida.minute,
        intervaloHoras: _intervaloHoras,
      ).formato24;
    });
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final app = AppScope.leer(context);
    final usuario = app.usuario;
    if (usuario == null) return;

    final horario = _hora == null
        ? null
        : Horario(
            hora: _hora!.hour,
            minuto: _hora!.minute,
            intervaloHoras: _intervaloHoras,
          );
    final fechaInicio = horario?.proximaDesde(app.ahora);
    final duracionDias =
        _tratamientoContinuo ? null : int.tryParse(_duracion.text.trim());

    setState(() {
      _error = null;
      _guardando = true;
    });
    try {
      final medicamento = MedicamentoBuilder()
          .conUsuario(usuario.id)
          .conNombre(_nombre.text)
          .conDosis(Dosis.tryParse(_dosis.text))
          .conHorario(horario)
          .conFechaInicio(fechaInicio ?? app.ahora)
          .conDuracionDias(duracionDias)
          .conInformacionAdicional(_info.text)
          .conFechaAlta(app.ahora)
          .construir();

      final primera = await app.guardarMedicamento(medicamento);
      if (!mounted) return;
      final cuando = mismoDia(primera, app.ahora) ? 'hoy' : 'mañana';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Guardado. Primera toma $cuando a las '
            '${formatoHora12(primera.hour, primera.minute)}.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } on DatosInvalidosException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.errores.first;
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediPagina(
      titulo: 'Nueva medicina',
      subtitulo: 'Te avisaremos a la hora que elijas',
      accionSuperior: const BotonVolver(),
      child: SingleChildScrollView(
        child: MediTarjeta(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MediCampo(
                  etiqueta: 'Nombre',
                  controller: _nombre,
                  hint: 'Ej. Losartán',
                  icono: Icons.medication_outlined,
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Escribe el nombre del medicamento.'
                      : null,
                ),
                MediCampo(
                  etiqueta: 'Dosis',
                  controller: _dosis,
                  hint: 'Ej. 1 tableta, media pastilla, 5 ml',
                  icono: Icons.colorize_outlined,
                  validator: (v) => Dosis.tryParse(v ?? '') == null
                      ? 'Escribe la dosis, por ejemplo: 1 tableta.'
                      : null,
                ),
                MediCampo(
                  etiqueta: 'Hora de la toma (toca para elegir)',
                  controller: _horario,
                  hint: 'Toca aquí para elegir la hora',
                  icono: Icons.access_time,
                  soloLectura: true,
                  onTap: _elegirHora,
                  validator: (_) =>
                      _hora == null ? 'Elige la hora de la toma.' : null,
                ),
                DropdownButtonFormField<int>(
                  initialValue: _intervaloHoras,
                  decoration: const InputDecoration(
                    labelText: 'Frecuencia',
                    helperText:
                        'Selecciona el intervalo indicado en la receta.',
                    prefixIcon: Icon(Icons.repeat),
                    border: OutlineInputBorder(),
                  ),
                  items: Horario.intervalosDisponibles
                      .map(
                        (horas) => DropdownMenuItem<int>(
                          value: horas,
                          child: Text(horas == 24
                              ? 'Una vez al día'
                              : 'Cada $horas horas'),
                        ),
                      )
                      .toList(),
                  onChanged: (horas) {
                    if (horas == null) return;
                    setState(() => _intervaloHoras = horas);
                  },
                ),
                const SizedBox(height: 16),
                if (!_tratamientoContinuo)
                  MediCampo(
                    etiqueta: 'Duración del tratamiento (días)',
                    controller: _duracion,
                    hint: 'Ej. 7',
                    icono: Icons.calendar_month_outlined,
                    teclado: TextInputType.number,
                    validator: (v) {
                      if (_tratamientoContinuo) return null;
                      final dias = int.tryParse((v ?? '').trim());
                      return dias == null || dias < 1 || dias > 365
                          ? 'Escribe de 1 a 365 días o marca tratamiento continuo.'
                          : null;
                    },
                  ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _tratamientoContinuo,
                  title: const Text('Tratamiento continuo (sin fecha de fin)'),
                  onChanged: (continuo) {
                    setState(() {
                      _tratamientoContinuo = continuo ?? false;
                      if (_tratamientoContinuo) _duracion.clear();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sigue la dosis, frecuencia y duración indicadas por tu profesional de salud. '
                          'MediHora solo te ayuda a llevar el horario.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                MediCampo(
                  etiqueta: 'Información adicional (opcional)',
                  controller: _info,
                  hint: 'Ej. tomar con un vaso de agua',
                  icono: Icons.notes,
                  maxLineas: 3,
                ),
                if (_error != null) MensajeError(_error!),
                BotonPrimario(
                  texto: _guardando ? 'Guardando...' : 'Guardar medicina',
                  icono: Icons.check,
                  onPressed: _guardando ? null : _guardar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
