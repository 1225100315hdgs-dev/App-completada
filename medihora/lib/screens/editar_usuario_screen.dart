import 'package:flutter/material.dart';

import '../domain/entities/usuario.dart';
import '../domain/value_objects/rol.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/medi_pagina.dart';

/// Formulario del ADMINISTRADOR: editar el nombre, el tipo de usuario y si la
/// cuenta está activa. Recibe como argumento de la ruta el id del usuario.
class EditarUsuarioScreen extends StatefulWidget {
  const EditarUsuarioScreen({super.key});

  @override
  State<EditarUsuarioScreen> createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _nombre = TextEditingController();
  RolUsuario _rol = RolUsuario.paciente;
  bool _activo = true;
  bool _cargado = false;
  bool _guardando = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cargado) return;
    _cargado = true;
    final id = ModalRoute.of(context)?.settings.arguments;
    if (id is! String) return;
    final u = AppScope.leer(context).usuarioPorId(id);
    if (u == null) return;
    _nombre.text = u.nombre;
    _rol = u.rol;
    _activo = u.activo;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar(Usuario u) async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final app = AppScope.leer(context);
    final nav = Navigator.of(context);
    final mensajes = ScaffoldMessenger.of(context);
    setState(() {
      _guardando = true;
      _error = null;
    });
    final error = await app.editarUsuario(u.id, nombre: _nombre.text, rol: _rol, activo: _activo);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _guardando = false;
        _error = error;
      });
      return;
    }
    nav.pop();
    mensajes
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Cambios guardados.')));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final id = ModalRoute.of(context)?.settings.arguments;
    final u = id is String ? app.usuarioPorId(id) : null;

    return MediPagina(
      titulo: 'Editar usuario',
      subtitulo: u?.correo.valor,
      accionSuperior: const BotonVolver(),
      child: u == null
          ? Center(
              child: Text('No encontramos esa cuenta.', style: Tema.cuerpo(color: context.c.textoSuave)),
            )
          : SingleChildScrollView(
              child: Form(
                key: _form,
                child: MediTarjeta(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MediCampo(
                        etiqueta: 'Nombre',
                        controller: _nombre,
                        icono: Icons.badge_outlined,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Escribe el nombre.' : null,
                      ),
                      Text(
                        'Tipo de usuario',
                        style: Tema.cuerpo().copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final r in RolUsuario.values)
                            ChoiceChip(
                              label: Text(r.etiqueta, style: const TextStyle(fontSize: 17)),
                              selected: _rol == r,
                              onSelected: (_) => setState(() => _rol = r),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _activo,
                        onChanged: (v) => setState(() => _activo = v),
                        title: Text('Cuenta activa', style: Tema.subtitulo(tamano: 18)),
                        subtitle: Text(
                          _activo
                              ? 'Puede iniciar sesión.'
                              : 'No podrá iniciar sesión hasta que la actives.',
                          style: Tema.cuerpo(color: context.c.textoSuave, tamano: 15),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_error != null) MensajeError(_error!),
                      BotonPrimario(
                        texto: _guardando ? 'Guardando...' : 'Guardar cambios',
                        icono: Icons.check,
                        onPressed: _guardando ? null : () => _guardar(u),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
