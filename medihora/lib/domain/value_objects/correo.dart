class Correo {
  const Correo._(this.valor);

  final String valor;

  static final RegExp _patron = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static Correo? tryParse(String texto) {
    final limpio = texto.trim().toLowerCase();
    return _patron.hasMatch(limpio) ? Correo._(limpio) : null;
  }

  factory Correo(String texto) {
    final correo = tryParse(texto);
    if (correo == null) {
      throw ArgumentError.value(texto, 'texto', 'Correo inválido');
    }
    return correo;
  }

  @override
  bool operator ==(Object other) => other is Correo && other.valor == valor;

  @override
  int get hashCode => valor.hashCode;

  @override
  String toString() => valor;
}
