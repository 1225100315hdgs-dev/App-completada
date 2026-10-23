import '../domain/entities/alerta_cuidador.dart';
import '../domain/entities/cuidador.dart';
import '../domain/entities/medicamento.dart';
import '../domain/entities/recordatorio.dart';
import '../domain/entities/toma.dart';
import '../domain/entities/usuario.dart';
import '../domain/value_objects/contacto.dart';
import '../domain/value_objects/correo.dart';
import '../domain/value_objects/dosis.dart';
import '../domain/value_objects/estados.dart';
import '../domain/value_objects/horario.dart';
import '../domain/value_objects/parentesco.dart';
import '../domain/value_objects/rol.dart';

/// Conversión entre entidades del dominio y mapas JSON para guardarlas.

DateTime _fecha(Object? v) => DateTime.parse(v as String);

DateTime? _fechaOpcional(Object? v) =>
    v == null ? null : DateTime.parse(v as String);

T _enumDe<T extends Enum>(List<T> valores, Object? nombre) =>
    valores.byName(nombre as String);

Map<String, dynamic> usuarioAMapa(Usuario u) => {
      'id': u.id,
      'nombre': u.nombre,
      'edad': u.edad,
      'correo': u.correo.valor,
      'contrasenaHash': u.contrasenaHash,
      'rol': u.rol.name,
      'activo': u.activo,
    };

Usuario usuarioDeMapa(Map<String, dynamic> m) => Usuario(
      id: m['id'] as String,
      nombre: m['nombre'] as String,
      edad: m['edad'] as int,
      correo: Correo(m['correo'] as String),
      contrasenaHash: m['contrasenaHash'] as String,
      rol: _enumDe(RolUsuario.values, m['rol']),
      activo: m['activo'] as bool? ?? true,
    );

Map<String, dynamic> cuidadorAMapa(Cuidador c) => {
      'id': c.id,
      'usuarioId': c.usuarioId,
      'nombre': c.nombre,
      'parentesco': c.parentesco.valor,
      'contactoTipo': c.contacto.tipo.name,
      'contactoValor': c.contacto.valor,
    };

Cuidador cuidadorDeMapa(Map<String, dynamic> m) => Cuidador(
      id: m['id'] as String,
      usuarioId: m['usuarioId'] as String,
      nombre: m['nombre'] as String,
      parentesco: Parentesco.tryParse(m['parentesco'] as String)!,
      contacto: Contacto(
        tipo: _enumDe(TipoContacto.values, m['contactoTipo']),
        valor: m['contactoValor'] as String,
      ),
    );

Map<String, dynamic> medicamentoAMapa(Medicamento m) => {
      'id': m.id,
      'usuarioId': m.usuarioId,
      'nombre': m.nombre,
      'dosisCantidad': m.dosis.cantidad,
      'dosisUnidad': m.dosis.unidad,
      'horarioHora': m.horario.hora,
      'horarioMinuto': m.horario.minuto,
      'horarioIntervaloHoras': m.horario.intervaloHoras,
      'horarioFrecuencia': m.horario.frecuencia.name,
      'fechaInicio': m.fechaInicio.toIso8601String(),
      'duracionDias': m.duracionDias,
      'indicacionAlimento': m.indicacionAlimento?.name,
      'informacionAdicional': m.informacionAdicional,
      'fechaAlta': m.fechaAlta.toIso8601String(),
    };

Medicamento medicamentoDeMapa(Map<String, dynamic> m) => Medicamento(
      id: m['id'] as String,
      usuarioId: m['usuarioId'] as String,
      nombre: m['nombre'] as String,
      dosis: Dosis(
        cantidad: (m['dosisCantidad'] as num).toDouble(),
        unidad: m['dosisUnidad'] as String,
      ),
      horario: Horario(
        hora: m['horarioHora'] as int,
        minuto: m['horarioMinuto'] as int,
        intervaloHoras: m['horarioIntervaloHoras'] as int? ?? 24,
        frecuencia: _enumDe(FrecuenciaHorario.values, m['horarioFrecuencia']),
      ),
      fechaInicio: m['fechaInicio'] == null ? null : _fecha(m['fechaInicio']),
      duracionDias: m['duracionDias'] as int?,
      indicacionAlimento: m['indicacionAlimento'] == null
          ? null
          : _enumDe(IndicacionAlimento.values, m['indicacionAlimento']),
      informacionAdicional: m['informacionAdicional'] as String?,
      fechaAlta: _fecha(m['fechaAlta']),
    );

Map<String, dynamic> tomaAMapa(Toma t) => {
      'id': t.id,
      'medicamentoId': t.medicamentoId,
      'fechaHoraProgramada': t.fechaHoraProgramada.toIso8601String(),
      'estado': t.estado.name,
      'fechaHoraConfirmacion': t.fechaHoraConfirmacion?.toIso8601String(),
      'origenConfirmacion': t.origenConfirmacion?.name,
    };

Toma tomaDeMapa(Map<String, dynamic> m) => Toma(
      id: m['id'] as String,
      medicamentoId: m['medicamentoId'] as String,
      fechaHoraProgramada: _fecha(m['fechaHoraProgramada']),
      estado: _enumDe(EstadoToma.values, m['estado']),
      fechaHoraConfirmacion: _fechaOpcional(m['fechaHoraConfirmacion']),
      origenConfirmacion: m['origenConfirmacion'] == null
          ? null
          : _enumDe(OrigenConfirmacion.values, m['origenConfirmacion']),
    );

Map<String, dynamic> recordatorioAMapa(Recordatorio r) => {
      'id': r.id,
      'tomaId': r.tomaId,
      'fechaHoraProgramada': r.fechaHoraProgramada.toIso8601String(),
      'tipo': r.tipo.name,
      'estado': r.estado.name,
    };

Recordatorio recordatorioDeMapa(Map<String, dynamic> m) => Recordatorio(
      id: m['id'] as String,
      tomaId: m['tomaId'] as String,
      fechaHoraProgramada: _fecha(m['fechaHoraProgramada']),
      tipo: _enumDe(TipoRecordatorio.values, m['tipo']),
      estado: _enumDe(EstadoRecordatorio.values, m['estado']),
    );

Map<String, dynamic> alertaAMapa(AlertaCuidador a) => {
      'id': a.id,
      'tomaId': a.tomaId,
      'cuidadorId': a.cuidadorId,
      'fechaHoraEnvio': a.fechaHoraEnvio.toIso8601String(),
      'estado': a.estado.name,
      'atendidaEn': a.atendidaEn?.toIso8601String(),
      'medio': a.medio?.name,
      'nota': a.nota,
    };

AlertaCuidador alertaDeMapa(Map<String, dynamic> m) => AlertaCuidador(
      id: m['id'] as String,
      tomaId: m['tomaId'] as String,
      cuidadorId: m['cuidadorId'] as String,
      fechaHoraEnvio: _fecha(m['fechaHoraEnvio']),
      estado: _enumDe(EstadoAlerta.values, m['estado']),
      atendidaEn: _fechaOpcional(m['atendidaEn']),
      medio:
          m['medio'] == null ? null : _enumDe(MedioContacto.values, m['medio']),
      nota: m['nota'] as String?,
    );
