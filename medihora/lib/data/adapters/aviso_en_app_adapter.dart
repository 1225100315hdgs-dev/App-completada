import 'package:flutter/material.dart';

import '../../domain/entities/toma_detalle.dart';
import '../../domain/services/aviso_service.dart';

/// Patrón Adapter: traduce "avisa que toca esta medicina" a "abre el aviso
/// dentro de la app".
/// Para usar notificaciones del sistema (Android/iPhone) se crea otro adaptador que
/// implemente [AvisoService] (por ejemplo con flutter_local_notifications) y se
/// cambia solo en main.dart.
class AvisoEnAppAdapter implements AvisoService {
  AvisoEnAppAdapter({required this.navigatorKey, required this.construirPantalla});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget Function(TomaDetalle detalle) construirPantalla;

  @override
  bool get disponible => navigatorKey.currentState != null;

  @override
  Future<void> mostrar(TomaDetalle detalle) async {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    final contexto = nav.overlay?.context;
    if (contexto == null) return;
    await showDialog<void>(
      context: contexto,
      barrierDismissible: false,
      builder: (_) => construirPantalla(detalle),
    );
  }
}
