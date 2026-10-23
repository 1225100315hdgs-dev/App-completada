import 'package:flutter/material.dart';

/// Los colores de MediHora para el modo claro y el modo oscuro.
///
/// La idea es que el color le diga a la persona qué hacer o qué pasó, sin tener que leer:
///  - AZUL  = la app, navegación y acciones principales (calma y confianza).
///  - VERDE = tomado / confirmar / todo bien.
///  - ÁMBAR = pendiente / atención (todavía hay tiempo).
///  - ROJO  = omitida / error / eliminar (solo cuando algo salió mal).
///
/// Se leen con `context.c`, así cambian solos cuando el teléfono cambia de modo.
@immutable
class TemaColores extends ThemeExtension<TemaColores> {
  const TemaColores({
    required this.primario,
    required this.primarioOscuro,
    required this.primarioSuave,
    required this.sobrePrimario,
    required this.fondo,
    required this.tarjeta,
    required this.campo,
    required this.texto,
    required this.textoSuave,
    required this.borde,
    required this.verde,
    required this.verdeSuave,
    required this.sobreVerde,
    required this.ambar,
    required this.ambarSuave,
    required this.rojo,
    required this.rojoSuave,
  });

  /// Azul de la marca: botones, iconos y selección.
  final Color primario;

  /// Azul fuerte para texto e iconos que van sobre [primarioSuave].
  final Color primarioOscuro;
  final Color primarioSuave;

  /// Color del texto sobre un fondo [primario].
  final Color sobrePrimario;

  final Color fondo;
  final Color tarjeta;

  /// Fondo de los campos de texto.
  final Color campo;
  final Color texto;
  final Color textoSuave;
  final Color borde;

  final Color verde;
  final Color verdeSuave;

  /// Color del texto sobre un fondo [verde].
  final Color sobreVerde;
  final Color ambar;
  final Color ambarSuave;
  final Color rojo;
  final Color rojoSuave;

  static const TemaColores claro = TemaColores(
    primario: Color(0xFF0B6E99),
    primarioOscuro: Color(0xFF084B6A),
    primarioSuave: Color(0xFFE1F0F7),
    sobrePrimario: Color(0xFFFFFFFF),
    fondo: Color(0xFFF2F6F9),
    tarjeta: Color(0xFFFFFFFF),
    campo: Color(0xFFF7FAFC),
    texto: Color(0xFF16222C),
    textoSuave: Color(0xFF52626E),
    borde: Color(0xFFD3DDE4),
    verde: Color(0xFF2E7D32),
    verdeSuave: Color(0xFFE4F3E5),
    sobreVerde: Color(0xFFFFFFFF),
    ambar: Color(0xFF9A5B00),
    ambarSuave: Color(0xFFFFF0D0),
    rojo: Color(0xFFC62828),
    rojoSuave: Color(0xFFFCE8E8),
  );

  static const TemaColores oscuro = TemaColores(
    primario: Color(0xFF58BDE8),
    primarioOscuro: Color(0xFFB4E3F6),
    primarioSuave: Color(0xFF163748),
    sobrePrimario: Color(0xFF042636),
    fondo: Color(0xFF0E181F),
    tarjeta: Color(0xFF16252E),
    campo: Color(0xFF1B2D38),
    texto: Color(0xFFE9F1F6),
    textoSuave: Color(0xFFA2B4C0),
    borde: Color(0xFF2C404D),
    verde: Color(0xFF78D17E),
    verdeSuave: Color(0xFF173320),
    sobreVerde: Color(0xFF082B0D),
    ambar: Color(0xFFF2B552),
    ambarSuave: Color(0xFF3B2D12),
    rojo: Color(0xFFFF8E86),
    rojoSuave: Color(0xFF3D1E1F),
  );

  @override
  TemaColores copyWith() => this;

  @override
  TemaColores lerp(ThemeExtension<TemaColores>? other, double t) {
    if (other is! TemaColores) return this;
    Color mezcla(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return TemaColores(
      primario: mezcla(primario, other.primario),
      primarioOscuro: mezcla(primarioOscuro, other.primarioOscuro),
      primarioSuave: mezcla(primarioSuave, other.primarioSuave),
      sobrePrimario: mezcla(sobrePrimario, other.sobrePrimario),
      fondo: mezcla(fondo, other.fondo),
      tarjeta: mezcla(tarjeta, other.tarjeta),
      campo: mezcla(campo, other.campo),
      texto: mezcla(texto, other.texto),
      textoSuave: mezcla(textoSuave, other.textoSuave),
      borde: mezcla(borde, other.borde),
      verde: mezcla(verde, other.verde),
      verdeSuave: mezcla(verdeSuave, other.verdeSuave),
      sobreVerde: mezcla(sobreVerde, other.sobreVerde),
      ambar: mezcla(ambar, other.ambar),
      ambarSuave: mezcla(ambarSuave, other.ambarSuave),
      rojo: mezcla(rojo, other.rojo),
      rojoSuave: mezcla(rojoSuave, other.rojoSuave),
    );
  }
}

/// `context.c.primario`, `context.c.texto`... los colores del modo actual.
extension TemaContexto on BuildContext {
  TemaColores get c => Theme.of(this).extension<TemaColores>() ?? TemaColores.claro;

  bool get esOscuro => Theme.of(this).brightness == Brightness.dark;
}

/// Estilos de texto. Si no se manda color, el texto toma el color del modo actual.
class Tema {
  /// Azul de la marca, igual en los dos modos (para la pantalla de inicio).
  static const Color marca = Color(0xFF0B6E99);

  static TextStyle titulo({Color? color, double tamano = 28}) => TextStyle(
        fontSize: tamano,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.15,
        letterSpacing: -0.3,
      );

  static TextStyle subtitulo({Color? color, double tamano = 19}) => TextStyle(
        fontSize: tamano,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.25,
      );

  static TextStyle cuerpo({Color? color, double tamano = 16}) => TextStyle(
        fontSize: tamano,
        color: color,
        height: 1.4,
      );
}

/// Arma el tema del modo claro o del oscuro. Se usa con `theme` y `darkTheme`
/// y `themeMode: ThemeMode.system`, así la app sigue la configuración del teléfono.
ThemeData construirTema(Brightness brillo) {
  final c = brillo == Brightness.dark ? TemaColores.oscuro : TemaColores.claro;
  final esquema = ColorScheme.fromSeed(seedColor: TemaColores.claro.primario, brightness: brillo)
      .copyWith(
    primary: c.primario,
    onPrimary: c.sobrePrimario,
    error: c.rojo,
    surface: c.tarjeta,
    onSurface: c.texto,
  );
  final base = brillo == Brightness.dark
      ? Typography.material2021().white
      : Typography.material2021().black;
  const redondeo = BorderRadius.all(Radius.circular(18));

  return ThemeData(
    useMaterial3: true,
    brightness: brillo,
    colorScheme: esquema,
    extensions: <ThemeExtension<dynamic>>[c],
    scaffoldBackgroundColor: c.fondo,
    textTheme: base.apply(bodyColor: c.texto, displayColor: c.texto),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        shape: const RoundedRectangleBorder(borderRadius: redondeo),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        shape: const RoundedRectangleBorder(borderRadius: redondeo),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.tarjeta,
      selectedColor: c.primarioSuave,
      side: BorderSide(color: c.borde),
      labelStyle: TextStyle(color: c.texto, fontWeight: FontWeight.w600),
      secondaryLabelStyle: TextStyle(color: c.primarioOscuro, fontWeight: FontWeight.w700),
      checkmarkColor: c.primarioOscuro,
      shape: const StadiumBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      backgroundColor: c.tarjeta,
      indicatorColor: c.primarioSuave,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (estados) => TextStyle(
          fontSize: 13,
          fontWeight: estados.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: estados.contains(WidgetState.selected) ? c.primarioOscuro : c.textoSuave,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (estados) => IconThemeData(
          size: 28,
          color: estados.contains(WidgetState.selected) ? c.primarioOscuro : c.textoSuave,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.borde, space: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: brillo == Brightness.dark ? c.primarioSuave : c.texto,
      contentTextStyle: TextStyle(
        color: brillo == Brightness.dark ? c.texto : Colors.white,
        fontSize: 16,
      ),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
  );
}
