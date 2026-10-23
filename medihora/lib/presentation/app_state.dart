import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/fechas.dart';
import '../core/ids.dart';
import '../core/reloj.dart';
import '../core/seguridad.dart';
import '../domain/entities/alerta_cuidador.dart';
import '../domain/entities/alerta_detalle.dart';
import '../domain/entities/cuidador.dart';
import '../domain/entities/medicamento.dart';
import '../domain/entities/toma_detalle.dart';
import '../domain/entities/usuario.dart';
import '../domain/repositories/medihora_repository.dart';
import '../domain/services/alerta_service.dart';
import '../domain/services/aviso_service.dart';
import '../domain/services/seguimiento_service.dart';
import '../domain/value_objects/contacto.dart';
import '../domain/value_objects/correo.dart';
import '../domain/value_objects/estados.dart';
import '../domain/value_objects/racha.dart';
import '../domain/value_objects/resumen_admin.dart';
import '../domain/value_objects/resumen_diario.dart';
import '../domain/value_objects/rol.dart';

/// Patrón Observer: es un ChangeNotifier. Cuando una toma cambia (se toma, se
/// pospone, se omite) avisa a todas las pantallas interesadas y se actualizan solas.
///
/// También recibe sus dependencias por el constructor (inyección de dependencias),
/// por eso se puede probar con un repositorio en memoria.
class AppState extends ChangeNotifier {
  AppState({
    required this.repo,
    required AvisoService avisos,
    required AlertaService alertas,
    Reloj? reloj,
    Duration tiempoLimite = const Duration(minutes: 30),
    Duration intervalo = const Duration(seconds: 15),
  })  : _avisos = avisos,
        _reloj = reloj ?? relojSistema,
        _intervalo = intervalo,
        seguimiento = SeguimientoService(
          repo: repo,
          alertas: alertas,
          tiempoLimite: tiempoLimite,
        );

  final MediHoraRepository repo;
  final SeguimientoService seguimiento;
  final AvisoService _avisos;
  final Reloj _reloj;
  final Duration _intervalo;

  Usuario? _usuario;
  Timer? _timer;
  String? _avisoActivoTomaId;
  bool _ocupado = false;
  bool _listoParaAvisos = false;

  DateTime get ahora => _reloj();
  Usuario? get usuario => _usuario;
  bool get haySesion => _usuario != null;
  RolUsuario? get rol => _usuario?.rol;

  // ---------------- Arranque y sesión ----------------

  /// Carga los datos guardados y recupera la sesión si la había.
  Future<void> iniciar() async {
    await repo.inicializar();
    final u = repo.usuarioEnSesion();
    // Una cuenta desactivada no conserva la sesión.
    _usuario = (u != null && u.activo) ? u : null;
    _arrancarSegunRol();
    notifyListeners();
  }

  /// Devuelve el mensaje de error, o null si todo salió bien.
  Future<String?> iniciarSesion(String correo, String contrasena) async {
    final c = Correo.tryParse(correo);
    if (c == null) return 'Escribe un correo válido.';
    if (contrasena.isEmpty) return 'Escribe tu contraseña.';
    final u = repo.usuarioPorCorreo(c);
    if (u == null || u.contrasenaHash != hashContrasena(contrasena)) {
      return 'Correo o contraseña incorrectos.';
    }
    if (!u.activo) return 'Tu cuenta está desactivada. Habla con el administrador.';
    await repo.abrirSesion(u.id);
    _usuario = u;
    _arrancarSegunRol();
    notifyListeners();
    return null;
  }

  /// RN-02: correo válido y único. Devuelve el mensaje de error, o null si salió bien.
  Future<String?> registrar({
    required String nombre,
    required String edad,
    required String correo,
    required String contrasena,
    RolUsuario rol = RolUsuario.paciente,
  }) async {
    final n = nombre.trim();
    if (n.isEmpty) return 'Escribe tu nombre.';
    final e = int.tryParse(edad.trim());
    if (e == null || e < 1 || e > 120) return 'Escribe una edad válida.';
    final c = Correo.tryParse(correo);
    if (c == null) return 'Escribe un correo válido.';
    if (contrasena.length < 4) return 'La contraseña debe tener al menos 4 caracteres.';
    if (repo.usuarioPorCorreo(c) != null) return 'Ese correo ya está registrado.';

    final u = Usuario(
      id: generarId(),
      nombre: n,
      edad: e,
      correo: c,
      contrasenaHash: hashContrasena(contrasena),
      rol: rol,
    );
    await repo.guardarUsuario(u);
    await repo.abrirSesion(u.id);
    _usuario = u;
    _arrancarSegunRol();
    notifyListeners();
    return null;
  }

  Future<void> cerrarSesion() async {
    _timer?.cancel();
    _timer = null;
    _usuario = null;
    _avisoActivoTomaId = null;
    await repo.cerrarSesion();
    notifyListeners();
  }

  /// Solo el paciente tiene tomas que vigilar; los otros tipos de usuario no necesitan el reloj.
  void _arrancarSegunRol() {
    _timer?.cancel();
    _timer = null;
    if (_usuario?.rol == RolUsuario.paciente) _arrancarSeguimiento();
  }

  // ---------------- Medicamentos ----------------

  List<Medicamento> get medicamentos {
    final u = _usuario;
    return u == null ? const <Medicamento>[] : repo.medicamentosDe(u.id);
  }

  /// Guarda el medicamento, programa sus tomas y devuelve cuándo será la primera.
  Future<DateTime> guardarMedicamento(Medicamento medicamento) async {
    await repo.guardarMedicamento(medicamento);
    final ahora = _reloj();
    await seguimiento.generarTomas(medicamento.usuarioId, ahora);
    notifyListeners();
    return seguimiento.proximaToma(medicamento, ahora);
  }

  Future<void> eliminarMedicamento(String id) async {
    await repo.eliminarMedicamento(id);
    notifyListeners();
  }

  // ---------------- Cuidadores ----------------

  List<Cuidador> get cuidadores {
    final u = _usuario;
    return u == null ? const <Cuidador>[] : repo.cuidadoresDe(u.id);
  }

  Future<void> guardarCuidador(Cuidador cuidador) async {
    await repo.guardarCuidador(cuidador);
    notifyListeners();
  }

  Future<void> eliminarCuidador(String id) async {
    await repo.eliminarCuidador(id);
    notifyListeners();
  }

  // ---------------- Tomas ----------------

  /// Las tomas de un día, ordenadas por hora.
  List<TomaDetalle> tomasDe(DateTime dia) {
    final u = _usuario;
    if (u == null) return const <TomaDetalle>[];
    final lista = <TomaDetalle>[];
    for (final t in repo.tomasDe(u.id)) {
      if (!mismoDia(t.fechaHoraProgramada, dia)) continue;
      final m = repo.medicamento(t.medicamentoId);
      if (m != null) lista.add(TomaDetalle(t, m));
    }
    lista.sort((a, b) => a.toma.fechaHoraProgramada.compareTo(b.toma.fechaHoraProgramada));
    return lista;
  }

  /// RN-11 y RN-21: la misma operación sirve para la notificación y para la casilla de la lista.
  Future<bool> confirmarToma(String tomaId, OrigenConfirmacion origen) async {
    final ok = await seguimiento.confirmarToma(tomaId, origen, _reloj());
    notifyListeners();
    return ok;
  }

  /// RN-12: posponer 10 minutos.
  Future<bool> posponerToma(String tomaId) async {
    final ok = await seguimiento.posponerToma(tomaId, _reloj());
    notifyListeners();
    return ok;
  }

  // ---------------- Vistas calculadas ----------------

  Racha get racha {
    final u = _usuario;
    if (u == null) return Racha.vacia;
    return seguimiento.calcularRacha(u.id, _reloj());
  }

  ResumenDiario resumenDe(DateTime dia) {
    final u = _usuario;
    if (u == null) {
      return ResumenDiario(fecha: soloFecha(dia), programadas: 0, tomadas: 0, omitidas: 0);
    }
    return seguimiento.resumenDiario(u.id, dia);
  }

  List<ResumenDiario> ultimosDias(int cantidad) {
    final u = _usuario;
    if (u == null) return const <ResumenDiario>[];
    return seguimiento.ultimosDias(u.id, _reloj(), cantidad);
  }

  /// RN-23: a quién se avisó por una toma omitida.
  List<String> avisosDeToma(String tomaId) {
    return repo.alertasDeToma(tomaId).map((a) {
      final c = repo.cuidador(a.cuidadorId);
      final quien = c == null ? 'un cuidador' : '${c.nombre} (${c.parentesco.valor})';
      final hora = formatoHora12(a.fechaHoraEnvio.hour, a.fechaHoraEnvio.minute);
      return a.estado == EstadoAlerta.enviada
          ? 'Se avisó a $quien a las $hora'
          : 'No se pudo avisar a $quien';
    }).toList();
  }

  // ---------------- Cuidador: sus alertas ----------------

  /// Las fichas de cuidador (de cualquier paciente) que usan el correo de esta cuenta.
  /// Así se vincula una cuenta de tipo Cuidador con los pacientes que la agregaron.
  List<Cuidador> get _vinculos {
    final u = _usuario;
    if (u == null || u.rol != RolUsuario.cuidador) return const <Cuidador>[];
    final propio = Contacto(tipo: TipoContacto.correo, valor: u.correo.valor);
    return repo.todosLosCuidadores().where((c) => c.contacto == propio).toList();
  }

  /// Las personas que me agregaron como cuidador.
  List<Usuario> get pacientesACargo {
    final ids = _vinculos.map((c) => c.usuarioId).toSet();
    final lista = <Usuario>[];
    for (final id in ids) {
      final p = repo.usuarioPorId(id);
      if (p != null) lista.add(p);
    }
    lista.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }

  /// Alertas dirigidas a esta cuenta, de la más reciente a la más antigua.
  List<AlertaDetalle> get alertasRecibidas {
    final ids = _vinculos.map((c) => c.id).toSet();
    if (ids.isEmpty) return const <AlertaDetalle>[];
    final lista = <AlertaDetalle>[];
    for (final a in repo.todasLasAlertas()) {
      if (!ids.contains(a.cuidadorId)) continue;
      final d = _detalleDe(a);
      if (d != null) lista.add(d);
    }
    lista.sort((a, b) => b.alerta.fechaHoraEnvio.compareTo(a.alerta.fechaHoraEnvio));
    return lista;
  }

  /// Una alerta, solo si esta cuenta puede verla (su cuidador o el administrador).
  AlertaDetalle? alertaVisible(String id) {
    final u = _usuario;
    final a = repo.alerta(id);
    if (u == null || a == null) return null;
    final d = _detalleDe(a);
    if (d == null) return null;
    if (u.rol == RolUsuario.admin) return d;
    if (u.rol == RolUsuario.cuidador && _vinculos.any((c) => c.id == a.cuidadorId)) return d;
    return null;
  }

  AlertaDetalle? _detalleDe(AlertaCuidador a) {
    final toma = repo.toma(a.tomaId);
    final med = toma == null ? null : repo.medicamento(toma.medicamentoId);
    final paciente = med == null ? null : repo.usuarioPorId(med.usuarioId);
    final cuidador = repo.cuidador(a.cuidadorId);
    if (toma == null || med == null || paciente == null || cuidador == null) return null;
    return AlertaDetalle(
      alerta: a,
      toma: toma,
      medicamento: med,
      paciente: paciente,
      cuidador: cuidador,
    );
  }

  /// Registra que el cuidador ya se comunicó con la persona.
  /// Devuelve el mensaje de error, o null si se guardó.
  Future<String?> registrarAtencion(String alertaId, MedioContacto medio, String nota) async {
    final u = _usuario;
    if (u == null || u.rol != RolUsuario.cuidador) {
      return 'Solo el cuidador puede registrar la atención.';
    }
    final d = alertaVisible(alertaId);
    if (d == null) return 'No encontramos esa alerta.';
    if (d.alerta.atendida) return 'Esta alerta ya fue atendida.';
    final texto = nota.trim();
    if (texto.length < 3) return 'Escribe una nota breve de lo que hablaron.';

    await repo.guardarAlerta(
      d.alerta.copyWith(atendidaEn: _reloj(), medio: medio, nota: texto),
    );
    notifyListeners();
    return null;
  }

  // ---------------- Administrador: cuentas y resumen ----------------

  /// Todas las cuentas: primero pacientes, luego cuidadores y administradores.
  List<Usuario> get usuarios {
    if (_usuario?.rol != RolUsuario.admin) return const <Usuario>[];
    final lista = repo.usuarios();
    lista.sort((a, b) {
      final porRol = a.rol.index.compareTo(b.rol.index);
      return porRol != 0 ? porRol : a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
    return lista;
  }

  Usuario? usuarioPorId(String id) => repo.usuarioPorId(id);

  /// Cuántas medicinas tiene registradas una cuenta (solo lo ve el administrador).
  int medicinasDe(String usuarioId) {
    if (_usuario?.rol != RolUsuario.admin) return 0;
    return repo.medicamentosDe(usuarioId).length;
  }

  ResumenAdmin get resumenAdmin {
    if (_usuario?.rol != RolUsuario.admin) return ResumenAdmin.vacio;
    final todos = repo.usuarios();
    return ResumenAdmin(
      usuarios: todos.length,
      pacientes: todos.where((u) => u.rol == RolUsuario.paciente).length,
      cuidadores: todos.where((u) => u.rol == RolUsuario.cuidador).length,
      administradores: todos.where((u) => u.rol == RolUsuario.admin).length,
      medicinas: repo.todosLosMedicamentos().length,
      tomasOmitidas: repo.todasLasTomas().where((t) => t.estado == EstadoToma.omitida).length,
      alertasSinAtender: repo.todasLasAlertas().where((a) => !a.atendida).length,
    );
  }

  /// Cambia el nombre, el tipo de usuario o activa/desactiva una cuenta.
  /// Devuelve el mensaje de error, o null si se guardó.
  Future<String?> editarUsuario(
    String id, {
    required String nombre,
    required RolUsuario rol,
    required bool activo,
  }) async {
    final yo = _usuario;
    if (yo == null || yo.rol != RolUsuario.admin) {
      return 'Solo el administrador puede editar cuentas.';
    }
    final objetivo = repo.usuarioPorId(id);
    if (objetivo == null) return 'No encontramos esa cuenta.';
    final n = nombre.trim();
    if (n.isEmpty) return 'Escribe el nombre.';
    if (objetivo.id == yo.id && (rol != RolUsuario.admin || !activo)) {
      return 'No puedes quitarte el acceso de administrador ni desactivar tu propia cuenta.';
    }

    final nuevo = objetivo.copiarCon(nombre: n, rol: rol, activo: activo);
    await repo.guardarUsuario(nuevo);
    if (nuevo.id == yo.id) _usuario = nuevo;
    notifyListeners();
    return null;
  }

  // ---------------- Avisos ----------------

  /// La pantalla principal avisa cuando ya está en pantalla. Así un aviso nunca se abre
  /// encima de la pantalla de Inicio o del Login. No notifica a nadie.
  void listoParaAvisos(bool listo) {
    _listoParaAvisos = listo;
  }

  /// Para la demostración: muestra el aviso de la primera toma pendiente de hoy.
  Future<bool> simularAviso() async {
    final u = _usuario;
    if (u == null || !_avisos.disponible) return false;
    if (_avisoActivoTomaId != null) return true;
    final pendientes =
        tomasDe(_reloj()).where((d) => d.toma.estado == EstadoToma.pendiente).toList();
    if (pendientes.isEmpty) return false;
    _mostrarAviso(pendientes.first);
    return true;
  }

  void _mostrarAviso(TomaDetalle detalle) {
    _avisoActivoTomaId = detalle.toma.id;
    unawaited(_avisos.mostrar(detalle).whenComplete(() {
      _avisoActivoTomaId = null;
    }));
  }

  // ---------------- Reloj interno ----------------

  void _arrancarSeguimiento() {
    _timer?.cancel();
    unawaited(_tick());
    _timer = Timer.periodic(_intervalo, (_) => unawaited(_tick()));
  }

  /// Cada pocos segundos: crea las tomas del día, omite las vencidas (y avisa a los
  /// cuidadores) y muestra el aviso de la toma que toca.
  Future<void> _tick() async {
    final u = _usuario;
    if (u == null || _ocupado) return;
    _ocupado = true;
    try {
      final ahora = _reloj();
      var cambio = (await seguimiento.generarTomas(u.id, ahora)) > 0;

      final omision = await seguimiento.omitirVencidas(u.id, ahora);
      if (omision.tomasOmitidas > 0) cambio = true;

      if (_avisoActivoTomaId == null && _listoParaAvisos && _avisos.disponible) {
        final detalle = await seguimiento.prepararSiguienteAviso(u.id, ahora);
        if (detalle != null) {
          cambio = true;
          _mostrarAviso(detalle);
        }
      }
      if (cambio) notifyListeners();
    } finally {
      _ocupado = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
