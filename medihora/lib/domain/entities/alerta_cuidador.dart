import '../value_objects/estados.dart';

/// Aviso a un cuidador cuando una toma no se confirma.
/// Resuelve la relación N a M entre Toma y Cuidador.
/// Cuando el cuidador tiene cuenta, registra aquí cómo atendió la alerta.
class AlertaCuidador {
  const AlertaCuidador({
    required this.id,
    required this.tomaId,
    required this.cuidadorId,
    required this.fechaHoraEnvio,
    required this.estado,
    this.atendidaEn,
    this.medio,
    this.nota,
  });

  final String id;
  final String tomaId;
  final String cuidadorId;
  final DateTime fechaHoraEnvio;
  final EstadoAlerta estado;

  /// Cuándo el cuidador registró que ya se comunicó con la persona.
  final DateTime? atendidaEn;
  final MedioContacto? medio;
  final String? nota;

  bool get atendida => atendidaEn != null;

  AlertaCuidador copyWith({DateTime? atendidaEn, MedioContacto? medio, String? nota}) {
    return AlertaCuidador(
      id: id,
      tomaId: tomaId,
      cuidadorId: cuidadorId,
      fechaHoraEnvio: fechaHoraEnvio,
      estado: estado,
      atendidaEn: atendidaEn ?? this.atendidaEn,
      medio: medio ?? this.medio,
      nota: nota ?? this.nota,
    );
  }
}
