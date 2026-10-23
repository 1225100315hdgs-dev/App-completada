import 'package:flutter/material.dart';

import '../../domain/value_objects/estados.dart';
import '../tema.dart';

/// Tarjeta redondeada donde van las listas y los formularios.
/// En modo claro lleva una sombra suave; en modo oscuro, solo el borde.
class MediTarjeta extends StatelessWidget {
  const MediTarjeta({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.bordeColor,
  });

  final Widget child;
  final EdgeInsets padding;

  /// Si es null usa el color de tarjeta del modo actual.
  final Color? color;
  final Color? bordeColor;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.tarjeta,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: bordeColor ?? c.borde.withAlpha(context.esOscuro ? 255 : 150)),
        boxShadow: context.esOscuro
            ? const <BoxShadow>[]
            : const [
                BoxShadow(color: Color(0x0F0B2A3A), blurRadius: 18, offset: Offset(0, 6)),
              ],
      ),
      child: child,
    );
  }
}

/// Campo de texto con su etiqueta arriba (siempre visible, no solo el hint).
class MediCampo extends StatelessWidget {
  const MediCampo({
    super.key,
    required this.etiqueta,
    required this.controller,
    this.hint,
    this.icono,
    this.obscuro = false,
    this.maxLineas = 1,
    this.validator,
    this.soloLectura = false,
    this.onTap,
    this.teclado,
    this.sufijo,
  });

  final String etiqueta;
  final TextEditingController controller;
  final String? hint;
  final IconData? icono;
  final bool obscuro;
  final int maxLineas;
  final String? Function(String?)? validator;
  final bool soloLectura;
  final VoidCallback? onTap;
  final TextInputType? teclado;
  final Widget? sufijo;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    OutlineInputBorder borde(Color color, [double ancho = 1.3]) => OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: color, width: ancho),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: Tema.cuerpo(tamano: 15).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscuro,
            maxLines: maxLineas,
            validator: validator,
            readOnly: soloLectura,
            onTap: onTap,
            keyboardType: teclado,
            style: Tema.cuerpo(tamano: 18),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: Tema.cuerpo(tamano: 16, color: c.textoSuave.withAlpha(180)),
              prefixIcon: icono == null ? null : Icon(icono, size: 24, color: c.primario),
              suffixIcon: sufijo,
              filled: true,
              fillColor: c.campo,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
              border: borde(c.borde),
              enabledBorder: borde(c.borde),
              focusedBorder: borde(c.primario, 2.4),
              errorBorder: borde(c.rojo),
              focusedErrorBorder: borde(c.rojo, 2.4),
              errorStyle: TextStyle(fontSize: 14, color: c.rojo, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mensaje de error visible (rojo suave con icono) para formularios.
class MensajeError extends StatelessWidget {
  const MensajeError(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.rojoSuave,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.rojo.withAlpha(110)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: c.rojo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: c.rojo, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón principal azul de ancho completo (Iniciar sesión, Guardar).
class BotonPrimario extends StatelessWidget {
  const BotonPrimario({super.key, required this.texto, required this.onPressed, this.icono});

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final estilo = FilledButton.styleFrom(
      backgroundColor: c.primario,
      foregroundColor: c.sobrePrimario,
    );
    return icono == null
        ? FilledButton(onPressed: onPressed, style: estilo, child: Text(texto))
        : FilledButton.icon(
            onPressed: onPressed,
            style: estilo,
            icon: Icon(icono, size: 24),
            label: Text(texto),
          );
  }
}

/// Botón verde: confirmar una toma ("Ya lo tomé").
class BotonExito extends StatelessWidget {
  const BotonExito({super.key, required this.texto, required this.onPressed, this.icono});

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: c.verde,
        foregroundColor: c.sobreVerde,
        minimumSize: const Size.fromHeight(64),
      ),
      icon: Icon(icono ?? Icons.check_circle, size: 28),
      label: Text(texto),
    );
  }
}

/// Botón con borde (acciones secundarias: Posponer, Probar aviso).
/// Con `peligro: true` se pinta en rojo (Cerrar sesión, Eliminar).
class BotonSecundario extends StatelessWidget {
  const BotonSecundario({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icono,
    this.peligro = false,
    this.sobreOscuro = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;
  final bool peligro;

  /// Para usarlo sobre fondos de color (pantalla de aviso).
  final bool sobreOscuro;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = sobreOscuro ? Colors.white : (peligro ? c.rojo : c.primario);
    final estilo = OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withAlpha(peligro ? 150 : 255), width: 1.8),
    );
    return icono == null
        ? OutlinedButton(onPressed: onPressed, style: estilo, child: Text(texto))
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: estilo,
            icon: Icon(icono, size: 24),
            label: Text(texto),
          );
  }
}

/// Botón flotante con texto: "Agregar medicina" se entiende sin adivinar el "+".
class MediFab extends StatelessWidget {
  const MediFab({super.key, required this.onPressed, required this.texto});

  final VoidCallback onPressed;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: c.primario,
      foregroundColor: c.sobrePrimario,
      elevation: 3,
      icon: const Icon(Icons.add, size: 28),
      label: Text(texto, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }
}

/// Flecha de volver, arriba a la izquierda, con área táctil grande.
class BotonVolver extends StatelessWidget {
  const BotonVolver({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: Icon(Icons.arrow_back, color: c.primarioOscuro, size: 28),
      style: IconButton.styleFrom(
        backgroundColor: c.primarioSuave,
        minimumSize: const Size(52, 52),
      ),
      tooltip: 'Volver',
    );
  }
}

/// Etiqueta de estado de una toma: Pendiente / Tomado / Omitida.
/// Lleva icono y color para que no dependa solo del color.
class EstadoChip extends StatelessWidget {
  const EstadoChip({super.key, required this.estado});

  final EstadoToma estado;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final String texto;
    final IconData icono;
    final Color color;
    final Color fondo;
    switch (estado) {
      case EstadoToma.pendiente:
        texto = 'Pendiente';
        icono = Icons.schedule;
        color = c.ambar;
        fondo = c.ambarSuave;
      case EstadoToma.tomada:
        texto = 'Tomado';
        icono = Icons.check_circle;
        color = c.verde;
        fondo = c.verdeSuave;
      case EstadoToma.omitida:
        texto = 'Omitida';
        icono = Icons.cancel;
        color = c.rojo;
        fondo = c.rojoSuave;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: 5),
          Text(texto, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
