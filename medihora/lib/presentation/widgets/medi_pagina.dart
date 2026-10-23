import 'package:flutter/material.dart';

import '../tema.dart';

/// Página base: fondo del modo actual, encabezado con título grande y,
/// a la izquierda, la acción de la pantalla (flecha de volver). Debajo va el contenido.
/// En el ancho de un teléfono ocupa todo; en pantallas grandes se centra con un ancho cómodo.
class MediPagina extends StatelessWidget {
  const MediPagina({
    super.key,
    required this.child,
    this.titulo,
    this.subtitulo,
    this.accionSuperior,
    this.fab,
  });

  final Widget child;
  final String? titulo;
  final String? subtitulo;

  /// Va arriba a la izquierda (volver).
  final Widget? accionSuperior;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.fondo,
      floatingActionButton: fab,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, fab != null ? 8 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (titulo != null || accionSuperior != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (accionSuperior != null) ...[
                          accionSuperior!,
                          const SizedBox(width: 10),
                        ],
                        if (titulo != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(titulo!, style: Tema.titulo()),
                                if (subtitulo != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      subtitulo!,
                                      style: Tema.cuerpo(color: c.textoSuave),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
