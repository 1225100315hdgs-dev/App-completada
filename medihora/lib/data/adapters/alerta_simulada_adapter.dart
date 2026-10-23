import 'package:flutter/foundation.dart';

import '../../domain/entities/cuidador.dart';
import '../../domain/services/alerta_service.dart';

/// Simula el envío al cuidador (lo escribe en la consola de depuración).
/// Para enviar de verdad se crea otro adaptador que implemente [AlertaService]
/// (SMS, correo, WhatsApp) llamando a un servidor.
class AlertaSimuladaAdapter implements AlertaService {
  final List<String> enviados = <String>[];

  @override
  Future<bool> enviar({required Cuidador cuidador, required String mensaje}) async {
    final registro = '[ALERTA -> ${cuidador.nombre} ${cuidador.contacto.valor}] $mensaje';
    enviados.add(registro);
    debugPrint(registro);
    return true;
  }
}
