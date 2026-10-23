import 'package:flutter/material.dart';

import '../core/ids.dart';
import '../domain/entities/cuidador.dart';
import '../domain/value_objects/contacto.dart';
import '../domain/value_objects/parentesco.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/medi_pagina.dart';

/// Formulario del PACIENTE: agregar o editar un cuidador.
/// Si recibe como argumento el id de un cuidador, lo edita.
class NuevoCuidadorScreen extends StatefulWidget {
  const NuevoCuidadorScreen({super.key});

  @override
  State<NuevoCuidadorScreen> createState() => _NuevoCuidadorScreenState();
}

class _NuevoCuidadorScreenState extends State<NuevoCuidadorScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _parentesco = TextEditingController();
  final TextEditingController _contacto = TextEditingController();
  Cuidador? _editando;
  bool _cargado = false;
  bool _guardando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cargado) return;
    _cargado = true;
    final id = ModalRoute.of(context)?.settings.arguments;
    if (id is! String) return;
    for (final c in AppScope.leer(context).cuidadores) {
      if (c.id == id) {
        _editando = c;
        _nombre.text = c.nombre;
        _parentesco.text = c.parentesco.valor;
        _contacto.text = c.contacto.valor;
      }
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _parentesco.dispose();
    _contacto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final app = AppScope.leer(context);
    final u = app.usuario;
    final parentesco = Parentesco.tryParse(_parentesco.text);
    final contacto = Contacto.tryParse(_contacto.text);
    if (u == null || parentesco == null || contacto == null) return;

    final nav = Navigator.of(context);
    final mensajes = ScaffoldMessenger.of(context);
    setState(() => _guardando = true);
    final nombre = _nombre.text.trim();
    await app.guardarCuidador(
      Cuidador(
        id: _editando?.id ?? generarId(),
        usuarioId: u.id,
        nombre: nombre,
        parentesco: parentesco,
        contacto: contacto,
      ),
    );
    nav.pop();
    mensajes
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_editando == null ? '$nombre ya es tu cuidador.' : 'Cambios guardados.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return MediPagina(
      titulo: _editando == null ? 'Nuevo cuidador' : 'Editar cuidador',
      subtitulo: 'Alguien de confianza',
      accionSuperior: const BotonVolver(),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MediTarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MediCampo(
                      etiqueta: 'Nombre',
                      controller: _nombre,
                      hint: 'Ej. Marta',
                      icono: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Escribe su nombre.' : null,
                    ),
                    MediCampo(
                      etiqueta: 'Parentesco',
                      controller: _parentesco,
                      hint: 'Ej. Hija, vecino, enfermera',
                      icono: Icons.family_restroom,
                      validator: (v) =>
                          Parentesco.tryParse(v ?? '') == null ? 'Escribe el parentesco.' : null,
                    ),
                    MediCampo(
                      etiqueta: 'Teléfono o correo',
                      controller: _contacto,
                      hint: 'Ej. 5512345678 o marta@correo.com',
                      icono: Icons.contact_phone_outlined,
                      teclado: TextInputType.emailAddress,
                      validator: (v) => Contacto.tryParse(v ?? '') == null
                          ? 'Escribe un teléfono de 10 a 15 dígitos o un correo válido.'
                          : null,
                    ),
                    Text(
                      'Si usas un correo, esa persona puede crear una cuenta de Cuidador '
                      'con ese mismo correo para ver las alertas dentro de la app.',
                      style: Tema.cuerpo(color: context.c.textoSuave, tamano: 14),
                    ),
                    const SizedBox(height: 16),
                    BotonPrimario(
                      texto: _guardando ? 'Guardando...' : 'Guardar',
                      icono: Icons.check,
                      onPressed: _guardando ? null : _guardar,
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
