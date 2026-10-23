import 'package:flutter/material.dart';

import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/medi_pagina.dart';

/// "Confirmación": se muestra después de confirmar una toma desde el aviso.
class ConfirmacionScreen extends StatelessWidget {
  const ConfirmacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final dias = app.racha.dias;

    return MediPagina(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(color: context.c.verdeSuave, shape: BoxShape.circle),
                child: Icon(Icons.check_circle, size: 100, color: context.c.verde),
              ),
              const SizedBox(height: 24),
              Text('¡Muy bien!', style: Tema.titulo(tamano: 36)),
              const SizedBox(height: 6),
              Text(
                'Tu toma quedó registrada.',
                textAlign: TextAlign.center,
                style: Tema.cuerpo(tamano: 20),
              ),
              const SizedBox(height: 20),
              if (dias > 0)
                MediTarjeta(
                  color: context.c.verdeSuave,
                  bordeColor: context.c.verde.withAlpha(120),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, color: context.c.verde, size: 36),
                      const SizedBox(width: 10),
                      Text(
                        dias == 1 ? 'Racha: 1 día seguido' : 'Racha: $dias días seguidos',
                        style: Tema.subtitulo(color: context.c.verde),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              BotonPrimario(
                texto: 'Entendido',
                icono: Icons.check,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
