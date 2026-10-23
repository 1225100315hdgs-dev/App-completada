import 'package:flutter_test/flutter_test.dart';
import 'package:medihora/data/memoria_medihora_repository.dart';
import 'package:medihora/domain/builders/medicamento_builder.dart';
import 'package:medihora/domain/entities/cuidador.dart';
import 'package:medihora/domain/entities/medicamento.dart';
import 'package:medihora/domain/entities/toma.dart';
import 'package:medihora/domain/entities/usuario.dart';
import 'package:medihora/domain/services/alerta_service.dart';
import 'package:medihora/domain/services/seguimiento_service.dart';
import 'package:medihora/domain/value_objects/contacto.dart';
import 'package:medihora/domain/value_objects/correo.dart';
import 'package:medihora/domain/value_objects/dosis.dart';
import 'package:medihora/domain/value_objects/estados.dart';
import 'package:medihora/domain/value_objects/horario.dart';
import 'package:medihora/domain/value_objects/parentesco.dart';

/// Alerta falsa: guarda los mensajes en lugar de enviarlos (prueba con Fake).
class AlertaFalsa implements AlertaService {
  final List<String> mensajes = <String>[];

  @override
  Future<bool> enviar(
      {required Cuidador cuidador, required String mensaje}) async {
    mensajes.add('${cuidador.nombre}: $mensaje');
    return true;
  }
}

void main() {
  group('Objetos de valor', () {
    test('Dosis entiende números, fracciones y palabras', () {
      final a = Dosis.tryParse('1 tableta')!;
      expect(a.cantidad, 1.0);
      expect(a.unidad, 'tableta');

      expect(Dosis.tryParse('media pastilla')!.cantidad, 0.5);
      expect(Dosis.tryParse('1/2 pastilla')!.cantidad, 0.5);
      expect(Dosis.tryParse('2,5 ml')!.cantidad, 2.5);
      expect(Dosis.tryParse('una cucharada')!.unidad, 'cucharada');
      expect(Dosis.tryParse('hola'), isNull);
      expect(Dosis.tryParse('dosis 5 mg'), isNull);
      expect(Dosis.tryParse('5mg')!.unidad, 'mg');
      expect(Dosis.tryParse('   '), isNull);
      expect(Dosis.tryParse('1 tableta')!.texto, '1 tableta');
      expect(Dosis.tryParse('media pastilla')!.texto, '1/2 pastilla');
    });

    test('Correo valida el formato', () {
      expect(Correo.tryParse('JM@Gmail.com')!.valor, 'jm@gmail.com');
      expect(Correo.tryParse('sin-arroba'), isNull);
      expect(Correo.tryParse('a@b'), isNull);
    });

    test('Horario valida y formatea', () {
      expect(Horario.tryParse('08:30')!.hora, 8);
      expect(Horario.tryParse('25:00'), isNull);
      expect(Horario.tryParse('8:75'), isNull);
      expect(const Horario(hora: 8, minuto: 30).formato12, '08:30 a.m.');
      expect(const Horario(hora: 20, minuto: 5).formato12, '08:05 p.m.');
      expect(const Horario(hora: 0, minuto: 0).formato12, '12:00 a.m.');
      expect(
        const Horario(hora: 8, minuto: 0, intervaloHoras: 8).tomasDelDia(
            DateTime(2026, 10, 15),
            inicio: DateTime(2026, 10, 15, 8)),
        [DateTime(2026, 10, 15, 8), DateTime(2026, 10, 15, 16)],
      );
      expect(
        const Horario(hora: 8, minuto: 0, intervaloHoras: 8).tomasDelDia(
            DateTime(2026, 10, 16),
            inicio: DateTime(2026, 10, 15, 8)),
        [
          DateTime(2026, 10, 16),
          DateTime(2026, 10, 16, 8),
          DateTime(2026, 10, 16, 16)
        ],
      );
    });

    test('Contacto reconoce teléfono y correo', () {
      expect(Contacto.tryParse('418 123 4567')!.tipo, TipoContacto.telefono);
      expect(Contacto.tryParse('418 123 4567')!.valor, '4181234567');
      expect(Contacto.tryParse('hija@mail.com')!.tipo, TipoContacto.correo);
      expect(Contacto.tryParse('123'), isNull);
    });

    test('Parentesco pone la primera letra en mayúscula', () {
      expect(Parentesco.tryParse('hija')!.valor, 'Hija');
      expect(Parentesco.tryParse('a'), isNull);
    });
  });

  group('MedicamentoBuilder', () {
    test('falla si faltan datos obligatorios', () {
      expect(
        () => MedicamentoBuilder()
            .conUsuario('u1')
            .conNombre('Losartán')
            .construir(),
        throwsA(isA<DatosInvalidosException>()),
      );
    });

    test('arma el medicamento y deja vacía la información opcional', () {
      final m = MedicamentoBuilder()
          .conUsuario('u1')
          .conNombre('  Losartán ')
          .conDosis(Dosis.tryParse('1 tableta'))
          .conHorario(const Horario(hora: 8, minuto: 0))
          .conInformacionAdicional('   ')
          .conFechaAlta(DateTime(2026, 10, 15))
          .construir();
      expect(m.nombre, 'Losartán');
      expect(m.informacionAdicional, isNull);
      expect(m.id, isNotEmpty);
    });
  });

  group('SeguimientoService', () {
    late MemoriaMediHoraRepository repo;
    late AlertaFalsa alertas;
    late SeguimientoService servicio;
    late Medicamento med;

    Future<void> agregarToma(String id, DateTime hora, EstadoToma estado) {
      return repo.guardarToma(
        Toma(
            id: id,
            medicamentoId: 'm1',
            fechaHoraProgramada: hora,
            estado: estado),
      );
    }

    setUp(() async {
      repo = MemoriaMediHoraRepository();
      alertas = AlertaFalsa();
      servicio = SeguimientoService(repo: repo, alertas: alertas);

      await repo.guardarUsuario(
        Usuario(
          id: 'u1',
          nombre: 'Juana María',
          edad: 74,
          correo: Correo('jm@gmail.com'),
          contrasenaHash: 'x',
        ),
      );
      med = Medicamento(
        id: 'm1',
        usuarioId: 'u1',
        nombre: 'Losartán',
        dosis: const Dosis(cantidad: 1, unidad: 'tableta'),
        horario: const Horario(hora: 8, minuto: 0),
        fechaAlta: DateTime(2026, 10, 15, 6, 0),
      );
      await repo.guardarMedicamento(med);
    });

    test('genera una toma con su recordatorio y no la duplica', () async {
      final ahora = DateTime(2026, 10, 15, 7, 0);
      expect(await servicio.generarTomas('u1', ahora), 1);
      expect(await servicio.generarTomas('u1', ahora), 0);

      final tomas = repo.tomasDe('u1');
      expect(tomas.length, 1);
      expect(tomas.first.estado, EstadoToma.pendiente);
      expect(repo.recordatoriosDeToma(tomas.first.id).length, 1);
    });

    test('no crea tomas anteriores al alta del medicamento', () async {
      await repo.guardarMedicamento(
        Medicamento(
          id: 'm2',
          usuarioId: 'u1',
          nombre: 'Metformina',
          dosis: const Dosis(cantidad: 1, unidad: 'tableta'),
          horario: const Horario(hora: 8, minuto: 0),
          fechaAlta: DateTime(2026, 10, 15, 9, 0),
        ),
      );
      final creadas =
          await servicio.generarTomas('u1', DateTime(2026, 10, 15, 9, 30));
      expect(creadas, 1);
      expect(repo.tomasDe('u1').single.medicamentoId, 'm1');
    });

    test('la próxima toma es hoy si falta, mañana si ya pasó', () {
      expect(servicio.proximaToma(med, DateTime(2026, 10, 15, 7, 0)),
          DateTime(2026, 10, 15, 8, 0));
      expect(servicio.proximaToma(med, DateTime(2026, 10, 15, 9, 0)),
          DateTime(2026, 10, 16, 8, 0));
    });

    test(
        'genera tomas cada 8 horas incluso al cambiar de día y respeta la duración',
        () async {
      final tratamiento = Medicamento(
        id: 'm2',
        usuarioId: 'u1',
        nombre: 'Antibiótico',
        dosis: const Dosis(cantidad: 1, unidad: 'tableta'),
        horario: const Horario(hora: 8, minuto: 0, intervaloHoras: 8),
        fechaAlta: DateTime(2026, 10, 15, 7),
        fechaInicio: DateTime(2026, 10, 15, 8),
        duracionDias: 1,
      );
      await repo.guardarMedicamento(tratamiento);

      expect(await servicio.generarTomas('u1', DateTime(2026, 10, 15, 7)), 3);
      expect(await servicio.generarTomas('u1', DateTime(2026, 10, 16)), 2);
      expect(
        repo
            .tomasDe('u1')
            .where((t) => t.medicamentoId == 'm2')
            .map((t) => t.fechaHoraProgramada)
            .toList(),
        [
          DateTime(2026, 10, 15, 8),
          DateTime(2026, 10, 15, 16),
          DateTime(2026, 10, 16),
        ],
      );
      expect(await servicio.generarTomas('u1', DateTime(2026, 10, 16, 8)), 0);
      expect(
        repo.tomasDe('u1').where((t) => t.medicamentoId == 'm2').length,
        3,
      );
    });

    test('el aviso aparece a la hora y no antes', () async {
      await servicio.generarTomas('u1', DateTime(2026, 10, 15, 7, 0));
      expect(
          await servicio.prepararSiguienteAviso(
              'u1', DateTime(2026, 10, 15, 7, 59)),
          isNull);

      final aviso = await servicio.prepararSiguienteAviso(
          'u1', DateTime(2026, 10, 15, 8, 0));
      expect(aviso, isNotNull);
      expect(aviso!.medicamento.nombre, 'Losartán');
      // Ya se marcó como enviado: no se repite.
      expect(
          await servicio.prepararSiguienteAviso(
              'u1', DateTime(2026, 10, 15, 8, 1)),
          isNull);
    });

    test('confirmar cancela el recordatorio pendiente y no se puede repetir',
        () async {
      await servicio.generarTomas('u1', DateTime(2026, 10, 15, 7, 0));
      final toma = repo.tomasDe('u1').first;

      final ok = await servicio.confirmarToma(
        toma.id,
        OrigenConfirmacion.lista,
        DateTime(2026, 10, 15, 8, 5),
      );
      expect(ok, isTrue);
      expect(repo.toma(toma.id)!.estado, EstadoToma.tomada);
      expect(repo.toma(toma.id)!.origenConfirmacion, OrigenConfirmacion.lista);
      expect(repo.recordatoriosDeToma(toma.id).single.estado,
          EstadoRecordatorio.cancelado);

      final otraVez = await servicio.confirmarToma(
        toma.id,
        OrigenConfirmacion.lista,
        DateTime(2026, 10, 15, 8, 6),
      );
      expect(otraVez, isFalse);
    });

    test('posponer deja la toma pendiente y crea un recordatorio a +10 minutos',
        () async {
      await servicio.generarTomas('u1', DateTime(2026, 10, 15, 7, 0));
      final toma = repo.tomasDe('u1').first;
      await servicio.prepararSiguienteAviso('u1', DateTime(2026, 10, 15, 8, 0));

      expect(await servicio.posponerToma(toma.id, DateTime(2026, 10, 15, 8, 0)),
          isTrue);
      expect(repo.toma(toma.id)!.estado, EstadoToma.pendiente);

      final recs = repo.recordatoriosDeToma(toma.id);
      final inicial =
          recs.firstWhere((r) => r.tipo == TipoRecordatorio.inicial);
      final pospuesto =
          recs.firstWhere((r) => r.tipo == TipoRecordatorio.pospuesto);
      expect(inicial.estado, EstadoRecordatorio.atendido);
      expect(pospuesto.estado, EstadoRecordatorio.programado);
      expect(pospuesto.fechaHoraProgramada, DateTime(2026, 10, 15, 8, 10));
    });

    test('omitir avisa una sola vez a cada cuidador', () async {
      await repo.guardarCuidador(
        Cuidador(
          id: 'c1',
          usuarioId: 'u1',
          nombre: 'Ana',
          parentesco: Parentesco.tryParse('hija')!,
          contacto: Contacto.tryParse('4181234567')!,
        ),
      );
      await repo.guardarCuidador(
        Cuidador(
          id: 'c2',
          usuarioId: 'u1',
          nombre: 'Luis',
          parentesco: Parentesco.tryParse('nieto')!,
          contacto: Contacto.tryParse('luis@mail.com')!,
        ),
      );
      await servicio.generarTomas('u1', DateTime(2026, 10, 15, 7, 0));
      final toma = repo.tomasDe('u1').first;

      // Antes del límite (30 min) no pasa nada.
      final antes =
          await servicio.omitirVencidas('u1', DateTime(2026, 10, 15, 8, 29));
      expect(antes.tomasOmitidas, 0);

      final r =
          await servicio.omitirVencidas('u1', DateTime(2026, 10, 15, 8, 31));
      expect(r.tomasOmitidas, 1);
      expect(r.alertas.length, 2);
      expect(alertas.mensajes.length, 2);
      expect(alertas.mensajes.first, contains('Losartán'));
      expect(repo.toma(toma.id)!.estado, EstadoToma.omitida);
      expect(repo.recordatoriosDeToma(toma.id).single.estado,
          EstadoRecordatorio.cancelado);

      final repetido =
          await servicio.omitirVencidas('u1', DateTime(2026, 10, 15, 9, 0));
      expect(repetido.tomasOmitidas, 0);
      expect(repetido.alertas, isEmpty);
      expect(repo.alertasDeToma(toma.id).length, 2);
    });

    test('la racha cuenta días completos y una omitida la rompe', () async {
      final hoy = DateTime(2026, 10, 15, 8, 0);
      await agregarToma('t13', DateTime(2026, 10, 13, 8, 0), EstadoToma.tomada);
      await agregarToma('t14', DateTime(2026, 10, 14, 8, 0), EstadoToma.tomada);
      await agregarToma('t15', hoy, EstadoToma.pendiente);

      // Hoy aún pendiente: no suma ni rompe.
      var racha = servicio.calcularRacha('u1', DateTime(2026, 10, 15, 8, 5));
      expect(racha.dias, 2);

      // Hoy completo: suma.
      await agregarToma('t15', hoy, EstadoToma.tomada);
      racha = servicio.calcularRacha('u1', DateTime(2026, 10, 15, 8, 5));
      expect(racha.dias, 3);
      expect(racha.fechaUltimoDiaCumplido, DateTime(2026, 10, 15));

      // Un día omitido en medio corta la cuenta.
      await agregarToma(
          't14', DateTime(2026, 10, 14, 8, 0), EstadoToma.omitida);
      racha = servicio.calcularRacha('u1', DateTime(2026, 10, 15, 8, 5));
      expect(racha.dias, 1);

      // Omitida hoy: racha en cero.
      await agregarToma('t15', hoy, EstadoToma.omitida);
      racha = servicio.calcularRacha('u1', DateTime(2026, 10, 15, 8, 5));
      expect(racha.dias, 0);
    });

    test('eliminar un medicamento borra sus tomas y recordatorios', () async {
      await servicio.generarTomas('u1', DateTime(2026, 10, 15, 7, 0));
      final toma = repo.tomasDe('u1').first;

      await repo.eliminarMedicamento('m1');
      expect(repo.medicamento('m1'), isNull);
      expect(repo.toma(toma.id), isNull);
      expect(repo.recordatoriosDeToma(toma.id), isEmpty);
    });

    test('el repositorio guarda y recupera todo como JSON', () async {
      await repo.guardarMedicamento(
        Medicamento(
          id: 'm2',
          usuarioId: 'u1',
          nombre: 'Tratamiento',
          dosis: const Dosis(cantidad: 1, unidad: 'tableta'),
          horario: const Horario(hora: 8, minuto: 0, intervaloHoras: 8),
          fechaAlta: DateTime(2026, 10, 15, 7),
          fechaInicio: DateTime(2026, 10, 15, 8),
          duracionDias: 7,
        ),
      );
      await servicio.generarTomas('u1', DateTime(2026, 10, 15, 7, 0));
      final copia = MemoriaMediHoraRepository()..cargarDesdeJson(repo.aJson());

      expect(copia.usuarioPorId('u1')!.nombre, 'Juana María');
      expect(copia.medicamento('m1')!.dosis.texto, '1 tableta');
      expect(copia.medicamento('m2')!.horario.intervaloHoras, 8);
      expect(copia.medicamento('m2')!.fechaInicio, DateTime(2026, 10, 15, 8));
      expect(copia.medicamento('m2')!.duracionDias, 7);
      expect(copia.tomasDe('u1').length, 3);
      expect(copia.recordatoriosDeUsuario('u1').length, 3);
    });
  });
}
