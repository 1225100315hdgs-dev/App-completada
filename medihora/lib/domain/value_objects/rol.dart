/// Los 3 tipos de usuario de MediHora; cada uno tiene su propio dashboard.
enum RolUsuario { paciente, cuidador, admin }

extension RolUsuarioX on RolUsuario {
  String get etiqueta {
    switch (this) {
      case RolUsuario.paciente:
        return 'Paciente';
      case RolUsuario.cuidador:
        return 'Cuidador';
      case RolUsuario.admin:
        return 'Administrador';
    }
  }

  String get descripcion {
    switch (this) {
      case RolUsuario.paciente:
        return 'Recibo recordatorios de mis medicinas';
      case RolUsuario.cuidador:
        return 'Acompaño a un familiar y recibo sus alertas';
      case RolUsuario.admin:
        return 'Veo la operación y administro las cuentas';
    }
  }
}
