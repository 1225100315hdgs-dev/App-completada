/// Relación con la persona usuaria: hijo, nieta, cuidador, vecina...
class Parentesco {
  const Parentesco._(this.valor);

  final String valor;

  static Parentesco? tryParse(String texto) {
    final t = texto.trim();
    if (t.length < 2) return null;
    return Parentesco._(t[0].toUpperCase() + t.substring(1));
  }

  @override
  bool operator ==(Object other) => other is Parentesco && other.valor == valor;

  @override
  int get hashCode => valor.hashCode;

  @override
  String toString() => valor;
}
