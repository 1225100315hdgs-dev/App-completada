/// Días seguidos con todas las tomas en "Tomada". Se calcula, no se captura.
class Racha {
  const Racha({required this.dias, this.fechaUltimoDiaCumplido});

  final int dias;
  final DateTime? fechaUltimoDiaCumplido;

  static const Racha vacia = Racha(dias: 0);
}
