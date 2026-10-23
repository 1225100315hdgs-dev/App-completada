import 'package:flutter/material.dart';

import '../../domain/value_objects/rol.dart';
import '../tema.dart';
import 'componentes.dart';

/// Etiqueta con el tipo de usuario.
class RolChip extends StatelessWidget {
  const RolChip({super.key, required this.rol});

  final RolUsuario rol;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: c.primarioSuave, borderRadius: BorderRadius.circular(20)),
      child: Text(
        rol.etiqueta,
        style: TextStyle(color: c.primarioOscuro, fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Número grande con su etiqueta (resumen de los dashboards).
class MediStat extends StatelessWidget {
  const MediStat({
    super.key,
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.color,
    this.fondo,
  });

  final IconData icono;
  final int valor;
  final String etiqueta;

  /// Si son null, azul de la marca.
  final Color? color;
  final Color? fondo;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return MediTarjeta(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: fondo ?? c.primarioSuave, shape: BoxShape.circle),
            child: Icon(icono, color: color ?? c.primario, size: 24),
          ),
          const SizedBox(height: 12),
          Text('$valor', style: Tema.titulo(tamano: 34)),
          const SizedBox(height: 2),
          Text(etiqueta, style: Tema.cuerpo(color: c.textoSuave, tamano: 15)),
        ],
      ),
    );
  }
}

/// Acceso grande a una lista o pantalla (con flecha a la derecha).
class MediAcceso extends StatelessWidget {
  const MediAcceso({
    super.key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: MediTarjeta(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: c.primarioSuave, shape: BoxShape.circle),
              child: Icon(icono, color: c.primario, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: Tema.subtitulo()),
                  const SizedBox(height: 2),
                  Text(subtitulo, style: Tema.cuerpo(color: c.textoSuave, tamano: 15)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textoSuave, size: 28),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío: un icono, un título y una explicación de qué hacer.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.mensaje,
  });

  final IconData icono;
  final String titulo;
  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: c.primarioSuave, shape: BoxShape.circle),
              child: Icon(icono, size: 60, color: c.primario),
            ),
            const SizedBox(height: 18),
            Text(titulo, textAlign: TextAlign.center, style: Tema.subtitulo(tamano: 20)),
            if (mensaje != null) ...[
              const SizedBox(height: 6),
              Text(
                mensaje!,
                textAlign: TextAlign.center,
                style: Tema.cuerpo(color: c.textoSuave),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
