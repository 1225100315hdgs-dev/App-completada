import 'medicamento.dart';
import 'toma.dart';

/// Una toma junto con su medicamento (lo que necesitan las pantallas).
class TomaDetalle {
  const TomaDetalle(this.toma, this.medicamento);

  final Toma toma;
  final Medicamento medicamento;
}
