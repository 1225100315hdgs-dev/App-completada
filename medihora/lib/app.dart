import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'presentation/app_scope.dart';
import 'presentation/app_state.dart';
import 'presentation/tema.dart';

/// Llave del navegador: permite abrir el aviso desde fuera de las pantallas.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MediHoraApp extends StatelessWidget {
  const MediHoraApp({super.key, required this.appState, required this.home, this.routes = const {}});

  final AppState appState;

  /// Pantalla inicial; se define desde main.dart.
  final Widget home;

  /// Rutas con nombre (se definen en main.dart).
  final Map<String, WidgetBuilder> routes;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: appState,
      child: MaterialApp(
        title: 'MediHora',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: construirTema(Brightness.light),
        darkTheme: construirTema(Brightness.dark),
        themeMode: ThemeMode.system, // sigue la configuración del teléfono
        locale: const Locale('es', 'MX'),
        supportedLocales: const [Locale('es', 'MX'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: home,
        routes: routes,
      ),
    );
  }
}
