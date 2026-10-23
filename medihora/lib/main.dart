import 'package:flutter/material.dart';

import 'app.dart';
import 'data/adapters/alerta_simulada_adapter.dart';
import 'data/adapters/aviso_en_app_adapter.dart';
import 'data/datos_demo.dart';
import 'data/local_medihora_repository.dart';
import 'presentation/app_state.dart';
import 'presentation/widgets/aviso_dialogo.dart';
import 'screens/atender_alerta_screen.dart';
import 'screens/confirmacion_screen.dart';
import 'screens/editar_usuario_screen.dart';
import 'screens/nueva_medicina_screen.dart';
import 'screens/nuevo_cuidador_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/rutas.dart';
import 'screens/splash_screen.dart';

/// Aquí se "arma" la app: se elige qué implementación usa cada pieza
/// y se registran las pantallas (carpeta lib/screens/).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repo = LocalMediHoraRepository();
  final appState = AppState(
    repo: repo,
    avisos: AvisoEnAppAdapter(
      navigatorKey: navigatorKey,
      construirPantalla: (detalle) => AvisoDialogo(aviso: detalle),
    ),
    alertas: AlertaSimuladaAdapter(),
  );
  // Carga lo guardado en el celular y recupera la sesión, si la había.
  await appState.iniciar();
  // Cuentas de ejemplo (paciente, cuidador y administrador) para probar sin registrarte.
  await sembrarDatosDemo(repo, DateTime.now());

  runApp(
    MediHoraApp(
      appState: appState,
      // Splashscreen -> (Login | dashboard según el tipo de usuario)
      home: const SplashScreen(),
      routes: {
        rutaRegistro: (_) => const RegistroScreen(),
        // Paciente
        rutaNuevaMedicina: (_) => const NuevaMedicinaScreen(),
        rutaNuevoCuidador: (_) => const NuevoCuidadorScreen(),
        rutaConfirmacion: (_) => const ConfirmacionScreen(),
        // Cuidador
        rutaAtenderAlerta: (_) => const AtenderAlertaScreen(),
        // Administrador
        rutaEditarUsuario: (_) => const EditarUsuarioScreen(),
      },
    ),
  );
}
