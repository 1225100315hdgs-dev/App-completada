import 'package:flutter/material.dart';

import '../domain/value_objects/correo.dart';
import '../domain/value_objects/rol.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/medi_pagina.dart';

/// "Registro": elegir el tipo de usuario y crear la cuenta.
/// Al terminar la sesión queda abierta y AuthGate muestra el dashboard que le toca.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _edad = TextEditingController();
  final TextEditingController _correo = TextEditingController();
  final TextEditingController _clave = TextEditingController();
  final TextEditingController _repetir = TextEditingController();
  RolUsuario _rol = RolUsuario.paciente;
  bool _oculta = true;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _edad.dispose();
    _correo.dispose();
    _clave.dispose();
    _repetir.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final app = AppScope.leer(context);
    final nav = Navigator.of(context);
    setState(() {
      _enviando = true;
      _error = null;
    });
    final error = await app.registrar(
      nombre: _nombre.text,
      edad: _edad.text,
      correo: _correo.text,
      contrasena: _clave.text,
      rol: _rol,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _enviando = false;
        _error = error;
      });
      return;
    }
    // La sesión ya quedó abierta: AuthGate muestra el dashboard. Se cierra esta pantalla.
    nav.popUntil((ruta) => ruta.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return MediPagina(
      titulo: 'Crear cuenta',
      subtitulo: 'Elige tu tipo de usuario',
      accionSuperior: const BotonVolver(),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in RolUsuario.values)
                _OpcionRol(rol: r, seleccionado: _rol == r, onTap: () => setState(() => _rol = r)),
              Text(
                'Para la demostración se puede elegir cualquier tipo de usuario.',
                style: Tema.cuerpo(color: context.c.textoSuave, tamano: 14),
              ),
              const SizedBox(height: 16),
              MediTarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MediCampo(
                      etiqueta: 'Nombre',
                      controller: _nombre,
                      hint: 'Cómo te llamas',
                      icono: Icons.badge_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Escribe tu nombre.' : null,
                    ),
                    MediCampo(
                      etiqueta: 'Edad',
                      controller: _edad,
                      hint: 'Ej. 72',
                      icono: Icons.cake_outlined,
                      teclado: TextInputType.number,
                      validator: (v) {
                        final e = int.tryParse((v ?? '').trim());
                        return (e == null || e < 1 || e > 120) ? 'Escribe una edad válida.' : null;
                      },
                    ),
                    MediCampo(
                      etiqueta: 'Correo',
                      controller: _correo,
                      hint: 'nombre@correo.com',
                      icono: Icons.email_outlined,
                      teclado: TextInputType.emailAddress,
                      validator: (v) =>
                          Correo.tryParse(v ?? '') == null ? 'Escribe un correo válido.' : null,
                    ),
                    MediCampo(
                      etiqueta: 'Contraseña',
                      controller: _clave,
                      hint: 'Mínimo 4 caracteres',
                      icono: Icons.lock_outline,
                      obscuro: _oculta,
                      validator: (v) => (v == null || v.length < 4)
                          ? 'La contraseña debe tener al menos 4 caracteres.'
                          : null,
                      sufijo: TextButton(
                        onPressed: () => setState(() => _oculta = !_oculta),
                        child: Text(_oculta ? 'Mostrar' : 'Ocultar'),
                      ),
                    ),
                    MediCampo(
                      etiqueta: 'Repite tu contraseña',
                      controller: _repetir,
                      hint: 'Otra vez la contraseña',
                      icono: Icons.lock_outline,
                      obscuro: _oculta,
                      validator: (v) => v != _clave.text ? 'Las contraseñas no coinciden.' : null,
                    ),
                    if (_error != null) MensajeError(_error!),
                    BotonPrimario(
                      texto: _enviando ? 'Creando...' : 'Crear cuenta',
                      icono: Icons.check,
                      onPressed: _enviando ? null : _crear,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconoDeRol(RolUsuario rol) {
  switch (rol) {
    case RolUsuario.paciente:
      return Icons.elderly;
    case RolUsuario.cuidador:
      return Icons.volunteer_activism;
    case RolUsuario.admin:
      return Icons.admin_panel_settings;
  }
}

/// Opción tocable para elegir el tipo de usuario.
class _OpcionRol extends StatelessWidget {
  const _OpcionRol({required this.rol, required this.seleccionado, required this.onTap});

  final RolUsuario rol;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: seleccionado,
        label: '${rol.etiqueta}. ${rol.descripcion}',
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: MediTarjeta(
            color: seleccionado ? context.c.primarioSuave : context.c.tarjeta,
            bordeColor: seleccionado ? context.c.primario : null,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(_iconoDeRol(rol), size: 34, color: context.c.primario),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rol.etiqueta, style: Tema.subtitulo()),
                      Text(
                        rol.descripcion,
                        style: Tema.cuerpo(color: context.c.textoSuave, tamano: 15),
                      ),
                    ],
                  ),
                ),
                Icon(
                  seleccionado ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: seleccionado ? context.c.primario : context.c.borde,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
