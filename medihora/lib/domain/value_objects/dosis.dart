/// Cuánto se toma: "1 tableta", "media pastilla", "5 ml", "una cucharada".
class Dosis {
  const Dosis({required this.cantidad, required this.unidad});

  final double cantidad;
  final String unidad;

  static final RegExp _patron = RegExp(
    r'^(\d+\s*/\s*\d+|\d+(?:[.,]\d+)?|(?:media|medio|una|un|dos|tres)\b)\s*(.*)$',
  );

  static const Map<String, double> _palabras = {
    'media': 0.5,
    'medio': 0.5,
    'una': 1.0,
    'un': 1.0,
    'dos': 2.0,
    'tres': 3.0,
  };

  static Dosis? tryParse(String texto) {
    final t = texto.trim().toLowerCase();
    if (t.isEmpty) return null;
    final m = _patron.firstMatch(t);
    if (m == null) return null;

    final bruto = m.group(1)!;
    final resto = m.group(2)!.trim();

    double? cantidad;
    if (_palabras.containsKey(bruto)) {
      cantidad = _palabras[bruto];
    } else if (bruto.contains('/')) {
      final partes = bruto.split('/');
      final a = double.tryParse(partes[0].trim());
      final b = double.tryParse(partes[1].trim());
      if (a != null && b != null && b != 0) cantidad = a / b;
    } else {
      cantidad = double.tryParse(bruto.replaceAll(',', '.'));
    }

    if (cantidad == null || cantidad <= 0) return null;
    return Dosis(cantidad: cantidad, unidad: resto.isEmpty ? 'dosis' : resto);
  }

  String get texto => '${_cantidadTexto()} $unidad';

  String _cantidadTexto() {
    if (cantidad == 0.5) return '1/2';
    if (cantidad == 0.25) return '1/4';
    if (cantidad == cantidad.roundToDouble()) return cantidad.toInt().toString();
    return cantidad.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is Dosis && other.cantidad == cantidad && other.unidad == unidad;

  @override
  int get hashCode => Object.hash(cantidad, unidad);

  @override
  String toString() => texto;
}
