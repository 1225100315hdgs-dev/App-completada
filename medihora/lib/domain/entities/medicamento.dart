import '../value_objects/dosis.dart';
import '../value_objects/estados.dart';
import '../value_objects/horario.dart';

class Medicamento {
  Medicamento({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.dosis,
    required this.horario,
    required this.fechaAlta,
    DateTime? fechaInicio,
    this.duracionDias,
    this.indicacionAlimento,
    this.informacionAdicional,
  }) : fechaInicio = fechaInicio ?? horario.proximaDesde(fechaAlta);

  final String id;
  final String usuarioId;
  final String nombre;
  final Dosis dosis;
  final Horario horario;

  /// Cuándo se registró el medicamento.
  final DateTime fechaAlta;

  /// Primera toma programada; permite empezar mañana si la hora elegida ya pasó.
  final DateTime fechaInicio;

  /// Nulo significa tratamiento continuo, sin fecha de fin configurada.
  final int? duracionDias;
  final IndicacionAlimento? indicacionAlimento;
  final String? informacionAdicional;

  String get descripcionDuracion =>
      duracionDias == null ? 'Tratamiento continuo' : '$duracionDias días';
}
