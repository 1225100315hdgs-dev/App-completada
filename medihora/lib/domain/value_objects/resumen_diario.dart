/// Vista calculada que alimenta el Historial (no es una entidad).
class ResumenDiario {
  const ResumenDiario({
    required this.fecha,
    required this.programadas,
    required this.tomadas,
    required this.omitidas,
  });

  final DateTime fecha;
  final int programadas;
  final int tomadas;
  final int omitidas;

  double get porcentaje => programadas == 0 ? 0 : tomadas * 100 / programadas;

  /// RN-20: un día está cumplido si todas sus tomas están en "Tomada".
  bool get cumplido => programadas > 0 && tomadas == programadas;

  bool get tieneOmitidas => omitidas > 0;
}
