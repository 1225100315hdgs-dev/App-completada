/// Números del dashboard del administrador (vista calculada, no es una entidad).
class ResumenAdmin {
  const ResumenAdmin({
    required this.usuarios,
    required this.pacientes,
    required this.cuidadores,
    required this.administradores,
    required this.medicinas,
    required this.tomasOmitidas,
    required this.alertasSinAtender,
  });

  final int usuarios;
  final int pacientes;
  final int cuidadores;
  final int administradores;
  final int medicinas;
  final int tomasOmitidas;
  final int alertasSinAtender;

  static const ResumenAdmin vacio = ResumenAdmin(
    usuarios: 0,
    pacientes: 0,
    cuidadores: 0,
    administradores: 0,
    medicinas: 0,
    tomasOmitidas: 0,
    alertasSinAtender: 0,
  );
}
