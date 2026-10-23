import '../value_objects/correo.dart';
import '../value_objects/rol.dart';

class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.edad,
    required this.correo,
    required this.contrasenaHash,
    this.rol = RolUsuario.paciente,
    this.activo = true,
  });

  final String id;
  final String nombre;
  final int edad;
  final Correo correo;
  final String contrasenaHash;
  final RolUsuario rol;

  /// Una cuenta desactivada por el administrador no puede iniciar sesión.
  final bool activo;

  Usuario copiarCon({String? nombre, RolUsuario? rol, bool? activo}) {
    return Usuario(
      id: id,
      nombre: nombre ?? this.nombre,
      edad: edad,
      correo: correo,
      contrasenaHash: contrasenaHash,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
    );
  }
}
