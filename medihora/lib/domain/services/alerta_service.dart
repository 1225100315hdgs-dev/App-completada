import '../entities/cuidador.dart';

/// Puerto para avisar a un cuidador (SMS, correo, WhatsApp...).
abstract class AlertaService {
  /// Devuelve true si el aviso se pudo enviar.
  Future<bool> enviar({required Cuidador cuidador, required String mensaje});
}
