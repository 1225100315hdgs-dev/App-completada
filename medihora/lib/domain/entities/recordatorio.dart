import '../value_objects/estados.dart';

/// Aviso ligado a una Toma. Incluye los reenvíos por "Posponer".
class Recordatorio {
  const Recordatorio({
    required this.id,
    required this.tomaId,
    required this.fechaHoraProgramada,
    required this.tipo,
    required this.estado,
  });

  final String id;
  final String tomaId;
  final DateTime fechaHoraProgramada;
  final TipoRecordatorio tipo;
  final EstadoRecordatorio estado;

  Recordatorio copyWith({EstadoRecordatorio? estado}) {
    return Recordatorio(
      id: id,
      tomaId: tomaId,
      fechaHoraProgramada: fechaHoraProgramada,
      tipo: tipo,
      estado: estado ?? this.estado,
    );
  }
}
