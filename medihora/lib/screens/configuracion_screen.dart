import 'package:flutter/material.dart';

import '../domain/value_objects/rol.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/dashboard.dart';
import '../presentation/widgets/medi_pagina.dart';

/// "Configuración": datos de la cuenta, probar el aviso (pacientes) y cerrar sesión.
class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  Future<void> _probarAviso(BuildContext context) async {
    final app = AppScope.leer(context);
    final mensajes = ScaffoldMessenger.of(context);
    final ok = await app.simularAviso();
    if (!ok) {
      mensajes
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No hay tomas pendientes hoy para probar el aviso.')),
        );
    }
  }

  Future<void> _salir(BuildContext context) async {
    final app = AppScope.leer(context);
    await app.cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final u = app.usuario;

    return MediPagina(
      titulo: 'Ajustes',
      subtitulo: 'Tu cuenta',
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          if (u != null)
            MediTarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: context.c.primarioSuave,
                        child: Text(
                          u.nombre.isEmpty ? '?' : u.nombre[0].toUpperCase(),
                          style: Tema.titulo(color: context.c.primarioOscuro, tamano: 28),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.nombre, style: Tema.titulo(tamano: 22)),
                            Text('${u.edad} años', style: Tema.cuerpo(color: context.c.textoSuave)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(u.correo.valor, style: Tema.cuerpo()),
                  const SizedBox(height: 10),
                  RolChip(rol: u.rol),
                ],
              ),
            ),
          const SizedBox(height: 14),
          if (u != null && u.rol == RolUsuario.paciente) ...[
            MediTarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Avisos', style: Tema.subtitulo()),
                  const SizedBox(height: 6),
                  Text(
                    'Si no confirmas una toma a tiempo, se avisa a tus cuidadores.',
                    style: Tema.cuerpo(color: context.c.textoSuave),
                  ),
                  const SizedBox(height: 14),
                  BotonSecundario(
                    texto: 'Probar un aviso ahora',
                    icono: Icons.notifications_active_outlined,
                    onPressed: () => _probarAviso(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          MediTarjeta(
            child: Row(
              children: [
                Icon(Icons.brightness_6_outlined, color: context.c.primario, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Apariencia', style: Tema.subtitulo()),
                      Text(
                        'La app usa el modo claro u oscuro de tu teléfono.',
                        style: Tema.cuerpo(color: context.c.textoSuave, tamano: 15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BotonSecundario(
            texto: 'Cerrar sesión',
            icono: Icons.logout,
            peligro: true,
            onPressed: () => _salir(context),
          ),
        ],
      ),
    );
  }
}
