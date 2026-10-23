import 'package:flutter_test/flutter_test.dart';
import 'package:medihora/data/datos_demo.dart';
import 'package:medihora/data/memoria_medihora_repository.dart';
import 'package:medihora/domain/entities/toma_detalle.dart';
import 'package:medihora/domain/services/alerta_service.dart';
import 'package:medihora/domain/services/aviso_service.dart';
import 'package:medihora/domain/value_objects/correo.dart';
import 'package:medihora/domain/value_objects/estados.dart';
import 'package:medihora/domain/value_objects/rol.dart';
import 'package:medihora/presentation/app_state.dart';

import 'dominio_test.dart';

/// Aviso falso: no muestra nada (en las pruebas no hay pantalla).
class _SinAviso implements AvisoService {
  @override
  bool get disponible => false;

  @override
  Future<void> mostrar(TomaDetalle detalle) async {}
}

/// 3 de la tarde: la Metformina de las 8 p.m. todavía no toca y el Losartán de las 8 a.m. ya pasó.
final DateTime _ahora = DateTime(2026, 10, 16, 15, 0);

Future<AppState> _app() async {
  final repo = MemoriaMediHoraRepository();
  await sembrarDatosDemo(repo, _ahora);
  final app = AppState(
    repo: repo,
    avisos: _SinAviso(),
    alertas: AlertaFalsa(),
    reloj: () => _ahora,
  );
  addTearDown(app.dispose);
  return app;
}

/// Inicia sesión con una cuenta de ejemplo y deja que termine el primer ciclo del reloj interno.
Future<AppState> _como(String correo) async {
  final app = await _app();
  expect(await app.iniciarSesion(correo, contrasenaDemo), isNull);
  await pumpEventQueue();
  return app;
}

void main() {
  group('Sesión y tipos de usuario', () {
    test('cada cuenta de ejemplo entra con su rol', () async {
      expect((await _como(correoPacienteDemo)).rol, RolUsuario.paciente);
      expect((await _como(correoCuidadorDemo)).rol, RolUsuario.cuidador);
      expect((await _como(correoAdminDemo)).rol, RolUsuario.admin);
    });

    test('rechaza datos incorrectos con un mensaje', () async {
      final app = await _app();
      expect(await app.iniciarSesion('no-es-correo', 'x'), isNotNull);
      expect(await app.iniciarSesion(correoAdminDemo, ''), isNotNull);
      expect(await app.iniciarSesion(correoAdminDemo, 'incorrecta'), isNotNull);
      expect(app.haySesion, isFalse);
    });

    test('el registro guarda el rol elegido y valida los datos', () async {
      final app = await _app();
      expect(
        await app.registrar(nombre: 'Ana', edad: '200', correo: 'ana@x.com', contrasena: '1234'),
        isNotNull,
      );
      expect(
        await app.registrar(
          nombre: 'Ana',
          edad: '41',
          correo: 'ana@x.com',
          contrasena: '1234',
          rol: RolUsuario.cuidador,
        ),
        isNull,
      );
      expect(app.rol, RolUsuario.cuidador);
      await app.cerrarSesion();
      expect(
        await app.registrar(nombre: 'Otra', edad: '30', correo: 'ANA@x.com', contrasena: '1234'),
        isNotNull,
      ); // el correo ya existe
    });

    test('una cuenta desactivada no puede iniciar sesión', () async {
      final admin = await _como(correoAdminDemo);
      expect(
        await admin.editarUsuario('demo-rosa', nombre: 'Rosa', rol: RolUsuario.paciente, activo: false),
        isNull,
      );
      await admin.cerrarSesion();
      final error = await admin.iniciarSesion(correoPacienteDemo, contrasenaDemo);
      expect(error, contains('desactivada'));
      expect(admin.haySesion, isFalse);
    });
  });

  group('Paciente: historial de ejemplo', () {
    test('tiene sus 2 medicinas y solo la toma de las 8 p.m. de hoy', () async {
      final rosa = await _como(correoPacienteDemo);
      expect(rosa.medicamentos.length, 2);
      final hoy = rosa.tomasDe(_ahora);
      expect(hoy.length, 1);
      expect(hoy.single.medicamento.nombre, 'Metformina');
      expect(hoy.single.toma.estado, EstadoToma.pendiente);
      expect(rosa.cuidadores.length, 2);
    });

    test('los días anteriores muestran las 2 omitidas y a quién se avisó', () async {
      final rosa = await _como(correoPacienteDemo);
      final ayer = DateTime(2026, 10, 15);
      final haceDos = DateTime(2026, 10, 14);
      final haceCuatro = DateTime(2026, 10, 12);
      expect(rosa.resumenDe(ayer).cumplido, isTrue);
      expect(rosa.resumenDe(haceDos).omitidas, 1);
      expect(rosa.resumenDe(haceCuatro).tieneOmitidas, isTrue);

      final avisos = rosa.avisosDeToma('demo-toma-demo-med-metformina-2');
      expect(avisos.length, 2);
      expect(avisos.any((a) => a.contains('Marta (Hija)')), isTrue);
      expect(rosa.ultimosDias(7).length, 7);
    });

    test('un paciente no ve datos de otros tipos de usuario', () async {
      final rosa = await _como(correoPacienteDemo);
      expect(rosa.usuarios, isEmpty);
      expect(rosa.alertasRecibidas, isEmpty);
      expect(rosa.resumenAdmin.usuarios, 0);
    });
  });

  group('Cuidador', () {
    test('ve solo las alertas dirigidas a su correo, la más reciente primero', () async {
      final marta = await _como(correoCuidadorDemo);
      final alertas = marta.alertasRecibidas;
      expect(alertas.length, 2); // las de Luis (solo teléfono) no son suyas
      expect(alertas.first.alerta.atendida, isFalse);
      expect(alertas.last.alerta.atendida, isTrue);
      expect(alertas.every((a) => a.paciente.nombre == 'Rosa'), isTrue);
      expect(marta.pacientesACargo.single.nombre, 'Rosa');
    });

    test('registrar la atención guarda el medio y la nota, una sola vez', () async {
      final marta = await _como(correoCuidadorDemo);
      final pendiente = marta.alertasRecibidas.firstWhere((a) => !a.alerta.atendida);
      final id = pendiente.alerta.id;

      expect(await marta.registrarAtencion(id, MedioContacto.visita, 'ok'), isNotNull); // muy corta
      expect(await marta.registrarAtencion(id, MedioContacto.visita, 'Fui a verla, está bien'), isNull);

      final guardada = marta.alertaVisible(id)!.alerta;
      expect(guardada.atendida, isTrue);
      expect(guardada.medio, MedioContacto.visita);
      expect(guardada.nota, 'Fui a verla, está bien');
      expect(guardada.atendidaEn, _ahora);
      expect(await marta.registrarAtencion(id, MedioContacto.llamada, 'Otra vez'), isNotNull);
    });

    test('solo el cuidador dueño o el administrador pueden ver una alerta', () async {
      // Un solo AppState y el mismo repositorio: se cambia de cuenta con cerrar e iniciar sesión.
      final app = await _como(correoCuidadorDemo);
      final id = app.alertasRecibidas.first.alerta.id;
      expect(app.alertaVisible(id), isNotNull);

      await app.cerrarSesion();
      expect(await app.iniciarSesion(correoPacienteDemo, contrasenaDemo), isNull);
      await pumpEventQueue();
      expect(app.alertaVisible(id), isNull);
      expect(await app.registrarAtencion(id, MedioContacto.llamada, 'Hola'), isNotNull);

      await app.cerrarSesion();
      expect(await app.iniciarSesion(correoAdminDemo, contrasenaDemo), isNull);
      expect(app.alertaVisible(id), isNotNull);
      expect(await app.registrarAtencion(id, MedioContacto.llamada, 'Hola'), isNotNull);
    });

    test('un cuidador nuevo sin vínculos tiene el estado vacío', () async {
      final app = await _app();
      expect(
        await app.registrar(
          nombre: 'Tere',
          edad: '50',
          correo: 'tere@x.com',
          contrasena: '1234',
          rol: RolUsuario.cuidador,
        ),
        isNull,
      );
      expect(app.alertasRecibidas, isEmpty);
      expect(app.pacientesACargo, isEmpty);
    });
  });

  group('Administrador', () {
    test('el resumen cuenta usuarios, medicinas, omitidas y alertas sin atender', () async {
      final admin = await _como(correoAdminDemo);
      final r = admin.resumenAdmin;
      expect(r.usuarios, 3);
      expect(r.pacientes, 1);
      expect(r.cuidadores, 1);
      expect(r.administradores, 1);
      expect(r.medicinas, 2);
      expect(r.tomasOmitidas, 2);
      expect(r.alertasSinAtender, 3); // Marta 1 + Luis 2
      expect(admin.medicinasDe('demo-rosa'), 2);
    });

    test('las cuentas salen ordenadas: pacientes, cuidadores y administradores', () async {
      final admin = await _como(correoAdminDemo);
      expect(admin.usuarios.map((u) => u.nombre).toList(), ['Rosa', 'Marta', 'Sofía']);
    });

    test('editar una cuenta cambia el nombre, el tipo y si está activa', () async {
      final admin = await _como(correoAdminDemo);
      expect(
        await admin.editarUsuario('demo-marta', nombre: '  Marta R.  ', rol: RolUsuario.paciente, activo: false),
        isNull,
      );
      final marta = admin.usuarioPorId('demo-marta')!;
      expect(marta.nombre, 'Marta R.');
      expect(marta.rol, RolUsuario.paciente);
      expect(marta.activo, isFalse);
    });

    test('editar valida permisos, nombre y la propia cuenta', () async {
      final admin = await _como(correoAdminDemo);
      expect(await admin.editarUsuario('no-existe', nombre: 'X', rol: RolUsuario.admin, activo: true), isNotNull);
      expect(await admin.editarUsuario('demo-marta', nombre: ' ', rol: RolUsuario.cuidador, activo: true), isNotNull);
      // no puede quitarse el acceso ni desactivarse
      expect(await admin.editarUsuario('demo-admin', nombre: 'Sofía', rol: RolUsuario.paciente, activo: true), isNotNull);
      expect(await admin.editarUsuario('demo-admin', nombre: 'Sofía', rol: RolUsuario.admin, activo: false), isNotNull);
      expect(admin.usuarioPorId('demo-admin')!.rol, RolUsuario.admin);
      // cambiarse el nombre sí se puede
      expect(await admin.editarUsuario('demo-admin', nombre: 'Sofía L.', rol: RolUsuario.admin, activo: true), isNull);
      expect(admin.usuario!.nombre, 'Sofía L.');

      final rosa = await _como(correoPacienteDemo);
      expect(await rosa.editarUsuario('demo-marta', nombre: 'X', rol: RolUsuario.admin, activo: true), isNotNull);
    });
  });

  group('Persistencia', () {
    test('el JSON conserva el rol, si la cuenta está activa y la atención de las alertas', () async {
      final marta = await _como(correoCuidadorDemo);
      final id = marta.alertasRecibidas.first.alerta.id;
      await marta.registrarAtencion(id, MedioContacto.mensaje, 'Le escribí y respondió');

      final copia = MemoriaMediHoraRepository()..cargarDesdeJson((marta.repo as MemoriaMediHoraRepository).aJson());
      expect(copia.usuarioPorCorreo(Correo(correoCuidadorDemo))!.rol, RolUsuario.cuidador);
      expect(copia.usuarioPorId('demo-rosa')!.activo, isTrue);
      final alerta = copia.alerta(id)!;
      expect(alerta.medio, MedioContacto.mensaje);
      expect(alerta.nota, 'Le escribí y respondió');
      expect(alerta.atendida, isTrue);
    });
  });
}
