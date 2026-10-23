import '../entities/toma_detalle.dart';

/// Puerto para avisar a la persona usuaria que le toca una medicina.
/// Se implementa con un Adapter (ver data/adapters). Hoy: pantalla dentro de la app.
/// Mañana: notificaciones del sistema, sin tocar el resto de la app.
abstract class AvisoService {
  /// Si ya se puede mostrar un aviso (por ejemplo, ya existe la pantalla de navegación).
  bool get disponible;

  /// Muestra el aviso. El Future termina cuando la persona lo cierra.
  Future<void> mostrar(TomaDetalle detalle);
}
