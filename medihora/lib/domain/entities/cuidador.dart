import '../value_objects/contacto.dart';
import '../value_objects/parentesco.dart';

/// Contacto de confianza. No tiene cuenta propia en la app.
class Cuidador {
  const Cuidador({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.parentesco,
    required this.contacto,
  });

  final String id;
  final String usuarioId;
  final String nombre;
  final Parentesco parentesco;
  final Contacto contacto;
}
