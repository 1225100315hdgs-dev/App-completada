import 'package:flutter/material.dart';

import '../domain/entities/cuidador.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/dashboard.dart';
import '../presentation/widgets/medi_pagina.dart';
import 'rutas.dart';

/// "Cuidador": la lista de personas de confianza a quienes se avisa
/// si no se confirma una toma. Con estado vacío.
class CuidadoresScreen extends StatelessWidget {
  const CuidadoresScreen({super.key});

  Future<void> _preguntarEliminar(BuildContext context, Cuidador c) async {
    final app = AppScope.leer(context);
    final mensajes = ScaffoldMessenger.of(context);
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.c.tarjeta,
        title: Text('¿Quitar a ${c.nombre}?', style: Tema.subtitulo()),
        content: Text(
          'Ya no se le avisará cuando olvides una toma.',
          style: Tema.cuerpo(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Quitar', style: TextStyle(color: context.c.rojo)),
          ),
        ],
      ),
    );
    if (seguro != true) return;
    await app.eliminarCuidador(c.id);
    mensajes
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${c.nombre} ya no es tu cuidador.')));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lista = app.cuidadores;

    return MediPagina(
      titulo: 'Cuidadores',
      subtitulo: lista.length == 1 ? '1 persona de confianza' : '${lista.length} personas de confianza',
      fab: MediFab(
        texto: 'Agregar cuidador',
        onPressed: () => Navigator.of(context).pushNamed(rutaNuevoCuidador),
      ),
      child: lista.isEmpty
          ? const EstadoVacio(
              icono: Icons.people_outline,
              titulo: 'Aún no tienes cuidadores',
              mensaje: 'Agrega a alguien de confianza para avisarle si olvidas una toma.',
            )
          : ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 90),
              children: [
                MediTarjeta(
                  color: context.c.primarioSuave,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: context.c.primarioOscuro),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Si no confirmas una toma a tiempo, se les avisa.',
                          style: Tema.cuerpo(tamano: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final c in lista)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MediTarjeta(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: context.c.primarioSuave,
                            child: Text(
                              c.nombre.isEmpty ? '?' : c.nombre[0].toUpperCase(),
                              style: Tema.subtitulo(color: context.c.primarioOscuro, tamano: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.nombre, style: Tema.subtitulo(tamano: 20)),
                                Text(
                                  c.parentesco.valor,
                                  style: Tema.cuerpo(color: context.c.textoSuave),
                                ),
                                Text(c.contacto.valor, style: Tema.cuerpo(tamano: 15)),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Más opciones',
                            color: context.c.tarjeta,
                            icon: const Icon(Icons.more_vert, size: 28),
                            onSelected: (valor) {
                              if (valor == 'editar') {
                                Navigator.of(context).pushNamed(rutaNuevoCuidador, arguments: c.id);
                              } else {
                                _preguntarEliminar(context, c);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem<String>(
                                value: 'editar',
                                child: Text('Editar', style: TextStyle(fontSize: 16)),
                              ),
                              PopupMenuItem<String>(
                                value: 'eliminar',
                                child: Text(
                                  'Quitar',
                                  style: TextStyle(fontSize: 16, color: context.c.rojo),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
