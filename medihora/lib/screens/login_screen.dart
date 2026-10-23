import 'package:flutter/material.dart';

import '../data/datos_demo.dart';
import '../domain/value_objects/correo.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import 'rutas.dart';

/// "Login": correo y contraseña, con validación visible.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _correo = TextEditingController();
  final TextEditingController _clave = TextEditingController();
  bool _oculta = true;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final app = AppScope.leer(context);
    setState(() {
      _enviando = true;
      _error = null;
    });
    final error = await app.iniciarSesion(_correo.text, _clave.text);
    // Si salió bien, AuthGate cambia al dashboard y esta pantalla desaparece.
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _error = error;
    });
  }

  void _usarCuenta(String correo) {
    setState(() {
      _correo.text = correo;
      _clave.text = contrasenaDemo;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.fondo,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(color: context.c.primario, shape: BoxShape.circle),
                    child: Icon(Icons.medication_rounded, size: 52, color: context.c.sobrePrimario),
                  ),
                  const SizedBox(height: 12),
                  Text('MediHora', style: Tema.titulo(tamano: 32)),
                  const SizedBox(height: 4),
                  Text('Tu medicina, a tu hora', style: Tema.cuerpo(color: context.c.textoSuave)),
                  const SizedBox(height: 24),
                  MediTarjeta(
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Iniciar sesión', style: Tema.titulo(tamano: 24)),
                          const SizedBox(height: 16),
                          MediCampo(
                            etiqueta: 'Correo',
                            controller: _correo,
                            hint: 'nombre@correo.com',
                            icono: Icons.email_outlined,
                            teclado: TextInputType.emailAddress,
                            validator: (v) => Correo.tryParse(v ?? '') == null
                                ? 'Escribe un correo válido.'
                                : null,
                          ),
                          MediCampo(
                            etiqueta: 'Contraseña',
                            controller: _clave,
                            hint: 'Tu contraseña',
                            icono: Icons.lock_outline,
                            obscuro: _oculta,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Escribe tu contraseña.' : null,
                            sufijo: TextButton(
                              onPressed: () => setState(() => _oculta = !_oculta),
                              child: Text(_oculta ? 'Mostrar' : 'Ocultar'),
                            ),
                          ),
                          if (_error != null) MensajeError(_error!),
                          BotonPrimario(
                            texto: _enviando ? 'Entrando...' : 'Entrar',
                            icono: Icons.login,
                            onPressed: _enviando ? null : _entrar,
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pushNamed(rutaRegistro),
                              child: const Text('¿No tienes cuenta? Regístrate'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  MediTarjeta(
                    color: context.c.primarioSuave,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.science_outlined, color: context.c.primario),
                            const SizedBox(width: 8),
                            Text('Cuentas de ejemplo', style: Tema.subtitulo(tamano: 17)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contraseña de todas: $contrasenaDemo',
                          style: Tema.cuerpo(color: context.c.textoSuave, tamano: 14),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.elderly, size: 20),
                              label: const Text('Paciente'),
                              onPressed: () => _usarCuenta(correoPacienteDemo),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.volunteer_activism, size: 20),
                              label: const Text('Cuidador'),
                              onPressed: () => _usarCuenta(correoCuidadorDemo),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.admin_panel_settings, size: 20),
                              label: const Text('Administrador'),
                              onPressed: () => _usarCuenta(correoAdminDemo),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
