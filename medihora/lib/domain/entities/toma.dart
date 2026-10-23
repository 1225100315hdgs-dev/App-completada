import '../value_objects/estados.dart';

/// Una ocurrencia concreta de un medicamento en una fecha y hora.
/// Es lo que se ve en "Mis medicinas" con su estado.
class Toma {
  const Toma({
    required this.id,
    required this.medicamentoId,
    required this.fechaHoraProgramada,
    required this.estado,
    this.fechaHoraConfirmacion,
    this.origenConfirmacion,
  });

  final String id;
  final String medicamentoId;
  final DateTime fechaHoraProgramada;
  final EstadoToma estado;
  final DateTime? fechaHoraConfirmacion;
  final OrigenConfirmacion? origenConfirmacion;

  Toma copyWith({
    EstadoToma? estado,
    DateTime? fechaHoraConfirmacion,
    OrigenConfirmacion? origenConfirmacion,
  }) {
    return Toma(
      id: id,
      medicamentoId: medicamentoId,
      fechaHoraProgramada: fechaHoraProgramada,
      estado: estado ?? this.estado,
      fechaHoraConfirmacion: fechaHoraConfirmacion ?? this.fechaHoraConfirmacion,
      origenConfirmacion: origenConfirmacion ?? this.origenConfirmacion,
    );
  }
}
