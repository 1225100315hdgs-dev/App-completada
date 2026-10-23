DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

bool mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Suma (o resta, con n negativo) días calendario sin problemas de horario de verano.
DateTime sumarDias(DateTime d, int n) =>
    DateTime(d.year, d.month, d.day + n, d.hour, d.minute, d.second);

String _dos(int n) => n.toString().padLeft(2, '0');

String formatoFecha(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}/${d.year}';

/// 8:05 -> "08:05 a.m."   20:30 -> "08:30 p.m."
String formatoHora12(int hora, int minuto) {
  final h12 = hora % 12 == 0 ? 12 : hora % 12;
  final sufijo = hora < 12 ? 'a.m.' : 'p.m.';
  return '${_dos(h12)}:${_dos(minuto)} $sufijo';
}
