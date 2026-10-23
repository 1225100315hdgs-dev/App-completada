import '../entities/alerta_cuidador.dart';
import '../entities/cuidador.dart';
import '../entities/medicamento.dart';
import '../entities/recordatorio.dart';
import '../entities/toma.dart';
import '../entities/usuario.dart';
import '../value_objects/correo.dart';

/// Patrón Repository: una sola puerta de acceso a los datos.
/// Las pantallas y la lógica no saben si vienen del celular o de internet.
abstract class MediHoraRepository {
  Future<void> inicializar();

  // Cuenta y sesión
  Usuario? usuarioPorCorreo(Correo correo);
  Usuario? usuarioPorId(String id);
  List<Usuario> usuarios();
  Future<void> guardarUsuario(Usuario usuario);
  Usuario? usuarioEnSesion();
  Future<void> abrirSesion(String usuarioId);
  Future<void> cerrarSesion();

  // Medicamentos
  List<Medicamento> medicamentosDe(String usuarioId);
  Medicamento? medicamento(String id);
  List<Medicamento> todosLosMedicamentos();
  Future<void> guardarMedicamento(Medicamento medicamento);

  /// Borra el medicamento y, en cascada, sus tomas, recordatorios y alertas.
  Future<void> eliminarMedicamento(String id);

  // Cuidadores
  List<Cuidador> cuidadoresDe(String usuarioId);
  Cuidador? cuidador(String id);
  List<Cuidador> todosLosCuidadores();
  Future<void> guardarCuidador(Cuidador cuidador);
  Future<void> eliminarCuidador(String id);

  // Tomas
  List<Toma> tomasDe(String usuarioId);
  Toma? toma(String id);
  List<Toma> todasLasTomas();
  Future<void> guardarToma(Toma toma);

  // Recordatorios
  List<Recordatorio> recordatoriosDeUsuario(String usuarioId);
  List<Recordatorio> recordatoriosDeToma(String tomaId);
  Future<void> guardarRecordatorio(Recordatorio recordatorio);

  // Alertas a cuidadores
  List<AlertaCuidador> alertasDeToma(String tomaId);
  List<AlertaCuidador> todasLasAlertas();
  AlertaCuidador? alerta(String id);
  Future<void> guardarAlerta(AlertaCuidador alerta);
}
