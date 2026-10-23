import '../../core/fechas.dart';
import '../../core/ids.dart';
import '../entities/alerta_cuidador.dart';
import '../entities/medicamento.dart';
import '../entities/recordatorio.dart';
import '../entities/toma.dart';
import '../entities/toma_detalle.dart';
import '../entities/usuario.dart';
import '../repositories/medihora_repository.dart';
import '../value_objects/estados.dart';
import '../value_objects/racha.dart';
import '../value_objects/resumen_diario.dart';
import 'alerta_service.dart';

class ResultadoOmision {
  const ResultadoOmision({required this.tomasOmitidas, required this.alertas});

  final int tomasOmitidas;
  final List<AlertaCuidador> alertas;
}

/// Lógica de negocio del contexto "Seguimiento de adherencia":
/// programar tomas, confirmar, posponer, omitir, avisar a cuidadores y calcular la racha.
class SeguimientoService {
  SeguimientoService({
    required this.repo,
    required this.alertas,
    this.tiempoLimite = const Duration(minutes: 30),
    this.duracionPosponer = const Duration(minutes: 10),
  });

  final MediHoraRepository repo;
  final AlertaService alertas;

  /// RN-13 / RN-14: tiempo máximo (desde la hora programada) para confirmar.
  /// Pasado ese tiempo la toma se omite, aunque se haya pospuesto.
  final Duration tiempoLimite;

  /// RN-12: "Posponer 10 minutos".
  final Duration duracionPosponer;

  /// Crea las tomas del día respetando el intervalo y fin de tratamiento.
  /// Es idempotente.
  Future<int> generarTomas(String usuarioId, DateTime ahora) async {
    var creadas = 0;
    final existentes = repo.tomasDe(usuarioId);
    for (final med in repo.medicamentosDe(usuarioId)) {
      final fin = med.duracionDias == null
          ? null
          : sumarDias(med.fechaInicio, med.duracionDias!);
      for (final hora in med.horario.tomasDelDia(
        ahora,
        desde: med.fechaInicio,
        inicio: med.fechaInicio,
      )) {
        if (fin != null && !hora.isBefore(fin)) continue;
        final yaExiste = existentes.any(
          (t) =>
              t.medicamentoId == med.id &&
              t.fechaHoraProgramada.isAtSameMomentAs(hora),
        );
        if (yaExiste) continue;

        final toma = Toma(
          id: generarId(),
          medicamentoId: med.id,
          fechaHoraProgramada: hora,
          estado: EstadoToma.pendiente,
        );
        await repo.guardarToma(toma);
        await repo.guardarRecordatorio(
          Recordatorio(
            id: generarId(),
            tomaId: toma.id,
            fechaHoraProgramada: hora,
            tipo: TipoRecordatorio.inicial,
            estado: EstadoRecordatorio.programado,
          ),
        );
        creadas++;
      }
    }
    return creadas;
  }

  /// Cuándo será la próxima toma de este medicamento.
  DateTime proximaToma(Medicamento med, DateTime ahora) {
    var dia = DateTime(ahora.year, ahora.month, ahora.day);
    final fin = med.duracionDias == null
        ? null
        : sumarDias(med.fechaInicio, med.duracionDias!);
    while (fin == null || dia.isBefore(fin)) {
      final desde = ahora.isAfter(med.fechaInicio) ? ahora : med.fechaInicio;
      final tomas =
          med.horario.tomasDelDia(dia, desde: desde, inicio: med.fechaInicio);
      for (final toma in tomas) {
        if (fin == null || toma.isBefore(fin)) return toma;
      }
      dia = dia.add(const Duration(days: 1));
    }
    return fin;
  }

  /// RN-11 / RN-21: confirma la toma (desde la notificación o desde la lista).
  /// Cancela los recordatorios que faltaban y evita la alerta.
  Future<bool> confirmarToma(
    String tomaId,
    OrigenConfirmacion origen,
    DateTime ahora,
  ) async {
    final toma = repo.toma(tomaId);
    if (toma == null || toma.estado != EstadoToma.pendiente) return false;

    await repo.guardarToma(
      toma.copyWith(
        estado: EstadoToma.tomada,
        fechaHoraConfirmacion: ahora,
        origenConfirmacion: origen,
      ),
    );

    for (final r in repo.recordatoriosDeToma(tomaId)) {
      if (r.estado == EstadoRecordatorio.programado) {
        await repo.guardarRecordatorio(
            r.copyWith(estado: EstadoRecordatorio.cancelado));
      } else if (r.estado == EstadoRecordatorio.enviado) {
        await repo.guardarRecordatorio(
            r.copyWith(estado: EstadoRecordatorio.atendido));
      }
    }
    return true;
  }

  /// RN-12: la toma sigue pendiente y se crea un recordatorio pospuesto.
  Future<bool> posponerToma(String tomaId, DateTime ahora) async {
    final toma = repo.toma(tomaId);
    if (toma == null || toma.estado != EstadoToma.pendiente) return false;

    for (final r in repo.recordatoriosDeToma(tomaId)) {
      if (r.estado == EstadoRecordatorio.enviado) {
        await repo.guardarRecordatorio(
            r.copyWith(estado: EstadoRecordatorio.atendido));
      }
    }
    await repo.guardarRecordatorio(
      Recordatorio(
        id: generarId(),
        tomaId: tomaId,
        fechaHoraProgramada: ahora.add(duracionPosponer),
        tipo: TipoRecordatorio.pospuesto,
        estado: EstadoRecordatorio.programado,
      ),
    );
    return true;
  }

  /// Busca el recordatorio vencido más antiguo de una toma pendiente,
  /// lo marca como enviado y devuelve la toma para mostrar el aviso.
  Future<TomaDetalle?> prepararSiguienteAviso(
      String usuarioId, DateTime ahora) async {
    Recordatorio? elegido;
    for (final r in repo.recordatoriosDeUsuario(usuarioId)) {
      if (r.estado != EstadoRecordatorio.programado) continue;
      if (r.fechaHoraProgramada.isAfter(ahora)) continue;
      final toma = repo.toma(r.tomaId);
      if (toma == null || toma.estado != EstadoToma.pendiente) continue;
      if (elegido == null ||
          r.fechaHoraProgramada.isBefore(elegido.fechaHoraProgramada)) {
        elegido = r;
      }
    }
    if (elegido == null) return null;

    final toma = repo.toma(elegido.tomaId);
    final med = toma == null ? null : repo.medicamento(toma.medicamentoId);
    if (toma == null || med == null) return null;

    await repo.guardarRecordatorio(
        elegido.copyWith(estado: EstadoRecordatorio.enviado));
    return TomaDetalle(toma, med);
  }

  /// RN-13 / RN-17: omite las tomas vencidas y avisa a cada cuidador (una sola vez).
  Future<ResultadoOmision> omitirVencidas(
      String usuarioId, DateTime ahora) async {
    final nuevas = <AlertaCuidador>[];
    var omitidas = 0;
    final usuario = repo.usuarioPorId(usuarioId);
    final cuidadores = repo.cuidadoresDe(usuarioId);

    for (final toma in repo.tomasDe(usuarioId)) {
      if (toma.estado != EstadoToma.pendiente) continue;
      if (toma.fechaHoraProgramada.add(tiempoLimite).isAfter(ahora)) continue;

      await repo.guardarToma(toma.copyWith(estado: EstadoToma.omitida));
      omitidas++;

      for (final r in repo.recordatoriosDeToma(toma.id)) {
        if (r.estado == EstadoRecordatorio.programado) {
          await repo.guardarRecordatorio(
              r.copyWith(estado: EstadoRecordatorio.cancelado));
        }
      }

      final med = repo.medicamento(toma.medicamentoId);
      if (usuario == null || med == null) continue;

      for (final cuidador in cuidadores) {
        final yaAvisado =
            repo.alertasDeToma(toma.id).any((a) => a.cuidadorId == cuidador.id);
        if (yaAvisado) continue;

        var enviada = false;
        try {
          enviada = await alertas.enviar(
            cuidador: cuidador,
            mensaje: mensajeAlerta(usuario, med, toma),
          );
        } catch (_) {
          enviada = false;
        }

        final alerta = AlertaCuidador(
          id: generarId(),
          tomaId: toma.id,
          cuidadorId: cuidador.id,
          fechaHoraEnvio: ahora,
          estado: enviada ? EstadoAlerta.enviada : EstadoAlerta.fallida,
        );
        await repo.guardarAlerta(alerta);
        nuevas.add(alerta);
      }
    }
    return ResultadoOmision(tomasOmitidas: omitidas, alertas: nuevas);
  }

  static String mensajeAlerta(Usuario usuario, Medicamento med, Toma toma) {
    return 'MediHora: ${usuario.nombre} no confirmó su toma de ${med.nombre} '
        '(${med.dosis.texto}) de las '
        '${formatoHora12(toma.fechaHoraProgramada.hour, toma.fechaHoraProgramada.minute)}.';
  }

  // ---------------- Vistas calculadas: resumen diario y racha ----------------

  ResumenDiario resumenDiario(String usuarioId, DateTime dia) {
    final tomas = repo
        .tomasDe(usuarioId)
        .where((t) => mismoDia(t.fechaHoraProgramada, dia))
        .toList();
    return ResumenDiario(
      fecha: soloFecha(dia),
      programadas: tomas.length,
      tomadas: tomas.where((t) => t.estado == EstadoToma.tomada).length,
      omitidas: tomas.where((t) => t.estado == EstadoToma.omitida).length,
    );
  }

  /// Los últimos [cantidad] días terminando en [hasta], del más antiguo al más reciente.
  List<ResumenDiario> ultimosDias(
      String usuarioId, DateTime hasta, int cantidad) {
    final fin = soloFecha(hasta);
    return List<ResumenDiario>.generate(
      cantidad,
      (i) => resumenDiario(usuarioId, sumarDias(fin, -(cantidad - 1 - i))),
    );
  }

  /// RN-20: días seguidos cumplidos. Hoy cuenta si ya está completo; si aún hay
  /// pendientes no suma ni rompe la racha; una toma omitida hoy la reinicia a 0.
  Racha calcularRacha(String usuarioId, DateTime ahora) {
    final hoy = soloFecha(ahora);
    final resumenHoy = resumenDiario(usuarioId, hoy);
    if (resumenHoy.tieneOmitidas) return Racha.vacia;

    var dias = 0;
    DateTime? ultimo;
    if (resumenHoy.cumplido) {
      dias = 1;
      ultimo = hoy;
    }

    var cursor = sumarDias(hoy, -1);
    while (true) {
      final r = resumenDiario(usuarioId, cursor);
      if (!r.cumplido) break;
      dias++;
      ultimo ??= cursor;
      cursor = sumarDias(cursor, -1);
    }
    return Racha(dias: dias, fechaUltimoDiaCumplido: ultimo);
  }
}
