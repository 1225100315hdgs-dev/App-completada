import 'alerta_cuidador.dart';
import 'cuidador.dart';
import 'medicamento.dart';
import 'toma.dart';
import 'usuario.dart';

/// Una alerta junto con todo lo que las pantallas necesitan mostrar:
/// la toma omitida, su medicina, la persona (paciente) y el cuidador avisado.
class AlertaDetalle {
  const AlertaDetalle({
    required this.alerta,
    required this.toma,
    required this.medicamento,
    required this.paciente,
    required this.cuidador,
  });

  final AlertaCuidador alerta;
  final Toma toma;
  final Medicamento medicamento;
  final Usuario paciente;
  final Cuidador cuidador;
}
