import 'package:flutter/material.dart';

import '../domain/value_objects/rol.dart';
import '../presentation/app_scope.dart';
import 'login_screen.dart';
import 'shells.dart';

/// Decide qué pantalla mostrar: el Login si no hay sesión, o la barra de pestañas
/// que le toca a cada tipo de usuario (paciente, cuidador o administrador).
/// Se actualiza sola cuando alguien entra o cierra sesión (Observer).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = AppScope.of(context).usuario;
    if (usuario == null) return const LoginScreen();
    switch (usuario.rol) {
      case RolUsuario.paciente:
        return const PacienteShell();
      case RolUsuario.cuidador:
        return const CuidadorShell();
      case RolUsuario.admin:
        return const AdminShell();
    }
  }
}
