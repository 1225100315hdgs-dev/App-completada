import '../core/fechas.dart';
import '../core/ids.dart';
import '../core/seguridad.dart';
import '../domain/entities/alerta_cuidador.dart';
import '../domain/entities/cuidador.dart';
import '../domain/entities/medicamento.dart';
import '../domain/entities/toma.dart';
import '../domain/entities/usuario.dart';
import '../domain/repositories/medihora_repository.dart';
import '../domain/value_objects/contacto.dart';
import '../domain/value_objects/correo.dart';
import '../domain/value_objects/dosis.dart';
import '../domain/value_objects/estados.dart';
import '../domain/value_objects/horario.dart';
import '../domain/value_objects/parentesco.dart';
import '../domain/value_objects/rol.dart';

/// Cuentas de ejemplo, una por tipo de usuario, para probar sin registrarte.
/// Todas usan la misma contraseña.
const String contrasenaDemo = 'medihora123';
const String correoPacienteDemo = 'rosa@medihora.app'; // Paciente
const String correoCuidadorDemo = 'cuidador@medihora.app'; // Cuidador
const String correoAdminDemo = 'admin@medihora.app'; // Administrador

const String _idRosa = 'demo-rosa';
const String _idMarta = 'demo-marta';
const String _idAdmin = 'demo-admin';

/// Crea los datos de ejemplo la primera vez (si no existe ya la paciente de ejemplo):
///  - Rosa (paciente) con 2 medicinas, 5 días de historial (con 2 tomas omitidas),
///    una cuidadora con cuenta (Marta) y un cuidador solo con teléfono (Luis).
///  - Marta (cuidadora): ve las alertas de Rosa, una ya atendida y otra pendiente.
///  - Sofía (administradora).
/// Los días del historial se calculan a partir de [ahora].
Future<void> sembrarDatosDemo(MediHoraRepository repo, DateTime ahora) async {
  final correoRosa = Correo(correoPacienteDemo);
  if (repo.usuarioPorCorreo(correoRosa) != null) return;

  final hash = hashContrasena(contrasenaDemo);
  await repo.guardarUsuario(
    Usuario(id: _idRosa, nombre: 'Rosa', edad: 72, correo: correoRosa, contrasenaHash: hash),
  );
  await repo.guardarUsuario(
    Usuario(
      id: _idMarta,
      nombre: 'Marta',
      edad: 45,
      correo: Correo(correoCuidadorDemo),
      contrasenaHash: hash,
      rol: RolUsuario.cuidador,
    ),
  );
  await repo.guardarUsuario(
    Usuario(
      id: _idAdmin,
      nombre: 'Sofía',
      edad: 38,
      correo: Correo(correoAdminDemo),
      contrasenaHash: hash,
      rol: RolUsuario.admin,
    ),
  );

  // Cuidadores de Rosa
  const idMartaCuidadora = 'demo-cuidadora-marta';
  const idLuisCuidador = 'demo-cuidador-luis';
  await repo.guardarCuidador(
    Cuidador(
      id: idMartaCuidadora,
      usuarioId: _idRosa,
      nombre: 'Marta',
      parentesco: Parentesco.tryParse('Hija')!,
      contacto: Contacto.tryParse(correoCuidadorDemo)!,
    ),
  );
  await repo.guardarCuidador(
    Cuidador(
      id: idLuisCuidador,
      usuarioId: _idRosa,
      nombre: 'Luis',
      parentesco: Parentesco.tryParse('Hijo')!,
      contacto: Contacto.tryParse('5512345678')!,
    ),
  );

  // Medicinas de Rosa. Se dan de alta "ahora" para que la app no cree tomas de hoy que ya
  // pasaron (se omitirían y mandarían alertas apenas se abre la demo). El historial de los
  // días anteriores se agrega a mano más abajo.
  final alta = ahora;
  final losartan = Medicamento(
    id: 'demo-med-losartan',
    usuarioId: _idRosa,
    nombre: 'Losartán',
    dosis: Dosis.tryParse('1 tableta')!,
    horario: const Horario(hora: 8, minuto: 0),
    fechaAlta: alta,
    indicacionAlimento: IndicacionAlimento.despuesDeComer,
  );
  final metformina = Medicamento(
    id: 'demo-med-metformina',
    usuarioId: _idRosa,
    nombre: 'Metformina',
    dosis: Dosis.tryParse('1 tableta')!,
    horario: const Horario(hora: 20, minuto: 0),
    fechaAlta: alta,
    indicacionAlimento: IndicacionAlimento.antesDeComer,
  );
  await repo.guardarMedicamento(losartan);
  await repo.guardarMedicamento(metformina);

  // Historial de los 5 días anteriores. Hace 4 días se omitió el Losartán y hace 2 días la Metformina.
  for (var atras = 5; atras >= 1; atras--) {
    final dia = sumarDias(ahora, -atras);
    for (final med in [losartan, metformina]) {
      final programada = med.horario.en(dia);
      final omitida = (atras == 4 && med == losartan) || (atras == 2 && med == metformina);
      final id = 'demo-toma-${med.id}-$atras';
      await repo.guardarToma(
        Toma(
          id: id,
          medicamentoId: med.id,
          fechaHoraProgramada: programada,
          estado: omitida ? EstadoToma.omitida : EstadoToma.tomada,
          fechaHoraConfirmacion: omitida ? null : programada.add(const Duration(minutes: 4)),
          origenConfirmacion: omitida ? null : OrigenConfirmacion.notificacion,
        ),
      );
      if (!omitida) continue;
      final envio = programada.add(const Duration(minutes: 30));
      // Alerta a Marta (con cuenta): la de hace 4 días ya está atendida, la de hace 2 no.
      await repo.guardarAlerta(
        AlertaCuidador(
          id: generarId(),
          tomaId: id,
          cuidadorId: idMartaCuidadora,
          fechaHoraEnvio: envio,
          estado: EstadoAlerta.enviada,
          atendidaEn: atras == 4 ? envio.add(const Duration(minutes: 12)) : null,
          medio: atras == 4 ? MedioContacto.llamada : null,
          nota: atras == 4 ? 'Hablé con ella: se le olvidó, ya se la tomó.' : null,
        ),
      );
      // Alerta a Luis (solo teléfono, sin cuenta).
      await repo.guardarAlerta(
        AlertaCuidador(
          id: generarId(),
          tomaId: id,
          cuidadorId: idLuisCuidador,
          fechaHoraEnvio: envio,
          estado: EstadoAlerta.enviada,
        ),
      );
    }
  }
}
