import 'correo.dart';

enum TipoContacto { telefono, correo }

/// Cómo se avisa a un cuidador: teléfono (10 a 15 dígitos) o correo.
class Contacto {
  const Contacto({required this.tipo, required this.valor});

  final TipoContacto tipo;
  final String valor;

  static Contacto? tryParse(String texto) {
    final t = texto.trim();
    if (t.contains('@')) {
      final correo = Correo.tryParse(t);
      if (correo == null) return null;
      return Contacto(tipo: TipoContacto.correo, valor: correo.valor);
    }
    final digitos = t.replaceAll(RegExp(r'[\s\-().+]'), '');
    if (RegExp(r'^\d{10,15}$').hasMatch(digitos)) {
      return Contacto(tipo: TipoContacto.telefono, valor: digitos);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is Contacto && other.tipo == tipo && other.valor == valor;

  @override
  int get hashCode => Object.hash(tipo, valor);

  @override
  String toString() => valor;
}
