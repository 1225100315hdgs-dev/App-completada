import '../../core/ids.dart';
import '../entities/medicamento.dart';
import '../value_objects/dosis.dart';
import '../value_objects/estados.dart';
import '../value_objects/horario.dart';

class DatosInvalidosException implements Exception {
  DatosInvalidosException(this.errores);

  final List<String> errores;

  @override
  String toString() => 'DatosInvalidosException: ${errores.join(' | ')}';
}

/// Patrón Builder: arma un Medicamento paso a paso.
/// Obligatorios: usuario, nombre, dosis y horario. Opcionales: indicación e información adicional.
class MedicamentoBuilder {
  String? _id;
  String? _usuarioId;
  String? _nombre;
  Dosis? _dosis;
  Horario? _horario;
  IndicacionAlimento? _indicacion;
  String? _informacion;
  DateTime? _fechaAlta;
  DateTime? _fechaInicio;
  int? _duracionDias;

  MedicamentoBuilder conId(String id) {
    _id = id;
    return this;
  }

  MedicamentoBuilder conUsuario(String usuarioId) {
    _usuarioId = usuarioId;
    return this;
  }

  MedicamentoBuilder conNombre(String nombre) {
    _nombre = nombre;
    return this;
  }

  MedicamentoBuilder conDosis(Dosis? dosis) {
    _dosis = dosis;
    return this;
  }

  MedicamentoBuilder conHorario(Horario? horario) {
    _horario = horario;
    return this;
  }

  MedicamentoBuilder conIndicacionAlimento(IndicacionAlimento? indicacion) {
    _indicacion = indicacion;
    return this;
  }

  MedicamentoBuilder conInformacionAdicional(String? informacion) {
    _informacion = informacion;
    return this;
  }

  MedicamentoBuilder conFechaAlta(DateTime fechaAlta) {
    _fechaAlta = fechaAlta;
    return this;
  }

  MedicamentoBuilder conFechaInicio(DateTime fechaInicio) {
    _fechaInicio = fechaInicio;
    return this;
  }

  MedicamentoBuilder conDuracionDias(int? duracionDias) {
    _duracionDias = duracionDias;
    return this;
  }

  List<String> validar() {
    final errores = <String>[];
    if (_usuarioId == null || _usuarioId!.isEmpty) {
      errores.add('Falta la persona usuaria.');
    }
    if (_nombre == null || _nombre!.trim().isEmpty) {
      errores.add('Escribe el nombre del medicamento.');
    }
    if (_dosis == null) {
      errores.add('Escribe la dosis, por ejemplo: 1 tableta.');
    }
    if (_horario == null) {
      errores.add('Elige la hora de la toma.');
    } else if (!Horario.intervalosDisponibles
        .contains(_horario!.intervaloHoras)) {
      errores.add('Elige un intervalo de toma disponible.');
    }
    if (_duracionDias != null && (_duracionDias! < 1 || _duracionDias! > 365)) {
      errores.add('La duración debe ser de 1 a 365 días.');
    }
    return errores;
  }

  Medicamento construir() {
    final errores = validar();
    if (errores.isNotEmpty) throw DatosInvalidosException(errores);

    final info = _informacion?.trim();
    final fechaAlta = _fechaAlta ?? DateTime.now();
    return Medicamento(
      id: _id ?? generarId(),
      usuarioId: _usuarioId!,
      nombre: _nombre!.trim(),
      dosis: _dosis!,
      horario: _horario!,
      fechaInicio: _fechaInicio ?? fechaAlta,
      duracionDias: _duracionDias,
      indicacionAlimento: _indicacion,
      informacionAdicional: (info == null || info.isEmpty) ? null : info,
      fechaAlta: fechaAlta,
    );
  }
}
