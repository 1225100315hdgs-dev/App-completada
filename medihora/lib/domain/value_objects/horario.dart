import '../../core/fechas.dart';

enum FrecuenciaHorario { diaria }

/// Hora de la primera toma y el intervalo entre tomas.
class Horario {
  const Horario({
    required this.hora,
    required this.minuto,
    this.intervaloHoras = 24,
    this.frecuencia = FrecuenciaHorario.diaria,
  });

  static const List<int> intervalosDisponibles = [4, 6, 8, 12, 24];

  final int hora;
  final int minuto;
  final int intervaloHoras;
  final FrecuenciaHorario frecuencia;

  static Horario? tryParse(String texto) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(texto.trim());
    if (m == null) return null;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    if (h > 23 || min > 59) return null;
    return Horario(hora: h, minuto: min);
  }

  /// La fecha y hora de esta toma en el día indicado.
  DateTime en(DateTime dia) =>
      DateTime(dia.year, dia.month, dia.day, hora, minuto);

  /// Toma programada más próxima a [ahora], usando la hora elegida como inicio.
  DateTime proximaDesde(DateTime ahora) {
    final inicio = en(ahora);
    final hoy = _tomasDelDia(ahora, desde: ahora, inicio: inicio);
    if (hoy.isNotEmpty) return hoy.first;
    return _tomasDelDia(ahora.add(const Duration(days: 1)), inicio: inicio)
        .first;
  }

  List<DateTime> tomasDelDia(DateTime dia,
          {DateTime? desde, DateTime? inicio}) =>
      _tomasDelDia(dia, desde: desde, inicio: inicio);

  List<DateTime> _tomasDelDia(DateTime dia,
      {DateTime? desde, DateTime? inicio}) {
    final inicioDia = DateTime(dia.year, dia.month, dia.day);
    final finDia = inicioDia.add(const Duration(days: 1));
    final ancla = inicio ?? en(inicioDia);
    final intervalo = Duration(hours: intervaloHoras);
    final diferencia = inicioDia.difference(ancla);
    final pasos = diferencia.isNegative
        ? 0
        : (diferencia.inMicroseconds + intervalo.inMicroseconds - 1) ~/
            intervalo.inMicroseconds;
    var toma = ancla.add(intervalo * pasos);
    final tomas = <DateTime>[];
    while (toma.isBefore(finDia)) {
      if (desde == null || !toma.isBefore(desde)) tomas.add(toma);
      toma = toma.add(intervalo);
    }
    return tomas;
  }

  String get descripcionFrecuencia =>
      intervaloHoras == 24 ? 'Una vez al día' : 'Cada $intervaloHoras horas';

  String get formato24 =>
      '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';

  String get formato12 => formatoHora12(hora, minuto);

  @override
  bool operator ==(Object other) =>
      other is Horario &&
      other.hora == hora &&
      other.minuto == minuto &&
      other.intervaloHoras == intervaloHoras &&
      other.frecuencia == frecuencia;

  @override
  int get hashCode => Object.hash(hora, minuto, intervaloHoras, frecuencia);

  @override
  String toString() => formato24;
}
