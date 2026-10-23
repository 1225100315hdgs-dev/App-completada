import 'package:flutter/material.dart';

import '../domain/entities/usuario.dart';
import '../domain/value_objects/rol.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/dashboard.dart';
import '../presentation/widgets/medi_pagina.dart';
import 'rutas.dart';

/// Lista del ADMINISTRADOR: todas las cuentas, con filtro por tipo y estado vacío.
/// Al tocar una se abre el formulario para editarla.
class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  /// null = todos.
  RolUsuario? _filtro;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final todos = app.usuarios;
    final lista = _filtro == null ? todos : todos.where((u) => u.rol == _filtro).toList();

    String resumen(Usuario u) {
      switch (u.rol) {
        case RolUsuario.paciente:
          final n = app.medicinasDe(u.id);
          return n == 1 ? '1 medicina' : '$n medicinas';
        case RolUsuario.cuidador:
          return 'Recibe alertas';
        case RolUsuario.admin:
          return 'Acceso total';
      }
    }

    return MediPagina(
      titulo: 'Usuarios',
      subtitulo: todos.length == 1 ? '1 cuenta' : '${todos.length} cuentas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('Todos', style: TextStyle(fontSize: 16)),
                selected: _filtro == null,
                onSelected: (_) => setState(() => _filtro = null),
              ),
              for (final r in RolUsuario.values)
                ChoiceChip(
                  label: Text(r.etiqueta, style: const TextStyle(fontSize: 16)),
                  selected: _filtro == r,
                  onSelected: (_) => setState(() => _filtro = r),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: lista.isEmpty
                ? const EstadoVacio(
                    icono: Icons.group_off,
                    titulo: 'No hay usuarios de este tipo',
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      for (final u in lista)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.of(context)
                                .pushNamed(rutaEditarUsuario, arguments: u.id),
                            child: MediTarjeta(
                              padding: const EdgeInsets.all(14),
                              color: u.activo ? context.c.tarjeta : context.c.fondo,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: context.c.primarioSuave,
                                    child: Text(
                                      u.nombre.isEmpty ? '?' : u.nombre[0].toUpperCase(),
                                      style: Tema.subtitulo(color: context.c.primarioOscuro, tamano: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(u.nombre, style: Tema.subtitulo(tamano: 20)),
                                        Text(
                                          u.correo.valor,
                                          style: Tema.cuerpo(color: context.c.textoSuave, tamano: 15),
                                        ),
                                        Text(
                                          u.activo ? resumen(u) : 'Cuenta desactivada',
                                          style: Tema.cuerpo(
                                            color: u.activo ? context.c.textoSuave : context.c.rojo,
                                            tamano: 14,
                                          ).copyWith(fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                  RolChip(rol: u.rol),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
