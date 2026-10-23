import '../domain/entities/alerta_cuidador.dart';
import '../domain/entities/cuidador.dart';
import '../domain/entities/medicamento.dart';
import '../domain/entities/recordatorio.dart';
import '../domain/entities/toma.dart';
import '../domain/entities/usuario.dart';
import '../domain/repositories/medihora_repository.dart';
import '../domain/value_objects/correo.dart';
import 'mappers.dart';

/// Implementación en memoria. También sirve para pruebas (no toca el disco).
/// Las lecturas son síncronas (caché en memoria); las escrituras llaman a [persistir].
class MemoriaMediHoraRepository implements MediHoraRepository {
  final Map<String, Usuario> _usuarios = {};
  final Map<String, Medicamento> _medicamentos = {};
  final Map<String, Cuidador> _cuidadores = {};
  final Map<String, Toma> _tomas = {};
  final Map<String, Recordatorio> _recordatorios = {};
  final Map<String, AlertaCuidador> _alertas = {};
  String? _sesionUsuarioId;

  /// Gancho para que las subclases guarden los cambios. Aquí no hace nada.
  Future<void> persistir() async {}

  @override
  Future<void> inicializar() async {}

  // ---------------- Cuenta y sesión ----------------
  @override
  Usuario? usuarioPorCorreo(Correo correo) {
    for (final u in _usuarios.values) {
      if (u.correo == correo) return u;
    }
    return null;
  }

  @override
  Usuario? usuarioPorId(String id) => _usuarios[id];

  @override
  List<Usuario> usuarios() => _usuarios.values.toList();

  @override
  Future<void> guardarUsuario(Usuario usuario) async {
    _usuarios[usuario.id] = usuario;
    await persistir();
  }

  @override
  Usuario? usuarioEnSesion() {
    final id = _sesionUsuarioId;
    return id == null ? null : _usuarios[id];
  }

  @override
  Future<void> abrirSesion(String usuarioId) async {
    _sesionUsuarioId = usuarioId;
    await persistir();
  }

  @override
  Future<void> cerrarSesion() async {
    _sesionUsuarioId = null;
    await persistir();
  }

  // ---------------- Medicamentos ----------------
  @override
  List<Medicamento> medicamentosDe(String usuarioId) =>
      _medicamentos.values.where((m) => m.usuarioId == usuarioId).toList();

  @override
  Medicamento? medicamento(String id) => _medicamentos[id];

  @override
  List<Medicamento> todosLosMedicamentos() => _medicamentos.values.toList();

  @override
  Future<void> guardarMedicamento(Medicamento medicamento) async {
    _medicamentos[medicamento.id] = medicamento;
    await persistir();
  }

  @override
  Future<void> eliminarMedicamento(String id) async {
    _medicamentos.remove(id);
    final idsTomas =
        _tomas.values.where((t) => t.medicamentoId == id).map((t) => t.id).toSet();
    _tomas.removeWhere((_, t) => idsTomas.contains(t.id));
    _recordatorios.removeWhere((_, r) => idsTomas.contains(r.tomaId));
    _alertas.removeWhere((_, a) => idsTomas.contains(a.tomaId));
    await persistir();
  }

  // ---------------- Cuidadores ----------------
  @override
  List<Cuidador> cuidadoresDe(String usuarioId) =>
      _cuidadores.values.where((c) => c.usuarioId == usuarioId).toList();

  @override
  Cuidador? cuidador(String id) => _cuidadores[id];

  @override
  List<Cuidador> todosLosCuidadores() => _cuidadores.values.toList();

  @override
  Future<void> guardarCuidador(Cuidador cuidador) async {
    _cuidadores[cuidador.id] = cuidador;
    await persistir();
  }

  @override
  Future<void> eliminarCuidador(String id) async {
    _cuidadores.remove(id);
    await persistir();
  }

  // ---------------- Tomas ----------------
  @override
  List<Toma> tomasDe(String usuarioId) {
    final ids = medicamentosDe(usuarioId).map((m) => m.id).toSet();
    return _tomas.values.where((t) => ids.contains(t.medicamentoId)).toList();
  }

  @override
  Toma? toma(String id) => _tomas[id];

  @override
  List<Toma> todasLasTomas() => _tomas.values.toList();

  @override
  Future<void> guardarToma(Toma toma) async {
    _tomas[toma.id] = toma;
    await persistir();
  }

  // ---------------- Recordatorios ----------------
  @override
  List<Recordatorio> recordatoriosDeUsuario(String usuarioId) {
    final ids = tomasDe(usuarioId).map((t) => t.id).toSet();
    return _recordatorios.values.where((r) => ids.contains(r.tomaId)).toList();
  }

  @override
  List<Recordatorio> recordatoriosDeToma(String tomaId) =>
      _recordatorios.values.where((r) => r.tomaId == tomaId).toList();

  @override
  Future<void> guardarRecordatorio(Recordatorio recordatorio) async {
    _recordatorios[recordatorio.id] = recordatorio;
    await persistir();
  }

  // ---------------- Alertas ----------------
  @override
  List<AlertaCuidador> alertasDeToma(String tomaId) =>
      _alertas.values.where((a) => a.tomaId == tomaId).toList();

  @override
  List<AlertaCuidador> todasLasAlertas() => _alertas.values.toList();

  @override
  AlertaCuidador? alerta(String id) => _alertas[id];

  @override
  Future<void> guardarAlerta(AlertaCuidador alerta) async {
    _alertas[alerta.id] = alerta;
    await persistir();
  }

  // ---------------- JSON ----------------
  Map<String, dynamic> aJson() => {
        'usuarios': _usuarios.values.map(usuarioAMapa).toList(),
        'sesion': _sesionUsuarioId,
        'medicamentos': _medicamentos.values.map(medicamentoAMapa).toList(),
        'cuidadores': _cuidadores.values.map(cuidadorAMapa).toList(),
        'tomas': _tomas.values.map(tomaAMapa).toList(),
        'recordatorios': _recordatorios.values.map(recordatorioAMapa).toList(),
        'alertas': _alertas.values.map(alertaAMapa).toList(),
      };

  List<Map<String, dynamic>> _lista(Object? v) => ((v as List<dynamic>?) ?? const <dynamic>[])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  void cargarDesdeJson(Map<String, dynamic> json) {
    _usuarios.clear();
    for (final m in _lista(json['usuarios'])) {
      final u = usuarioDeMapa(m);
      _usuarios[u.id] = u;
    }
    _sesionUsuarioId = json['sesion'] as String?;

    _medicamentos.clear();
    for (final m in _lista(json['medicamentos'])) {
      final x = medicamentoDeMapa(m);
      _medicamentos[x.id] = x;
    }
    _cuidadores.clear();
    for (final m in _lista(json['cuidadores'])) {
      final x = cuidadorDeMapa(m);
      _cuidadores[x.id] = x;
    }
    _tomas.clear();
    for (final m in _lista(json['tomas'])) {
      final x = tomaDeMapa(m);
      _tomas[x.id] = x;
    }
    _recordatorios.clear();
    for (final m in _lista(json['recordatorios'])) {
      final x = recordatorioDeMapa(m);
      _recordatorios[x.id] = x;
    }
    _alertas.clear();
    for (final m in _lista(json['alertas'])) {
      final x = alertaDeMapa(m);
      _alertas[x.id] = x;
    }
  }
}
