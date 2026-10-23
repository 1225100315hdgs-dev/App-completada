import 'dart:async';

import 'package:flutter/material.dart';

import '../presentation/tema.dart';
import 'auth_gate.dart';

/// "Inicio": pantalla de carga con el logo y paso al Login
/// (o directo al dashboard si ya había una sesión abierta).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.duracion = const Duration(milliseconds: 2200)});

  final Duration duracion;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _temporizador = Timer(widget.duracion, _continuar);
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  void _continuar() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder: (_, animacion, __, hijo) =>
            FadeTransition(opacity: animacion, child: hijo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tema.marca,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const Spacer(flex: 3),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                builder: (context, escala, hijo) => Opacity(
                  opacity: escala.clamp(0.0, 1.0).toDouble(),
                  child: Transform.scale(scale: escala, child: hijo),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.medication_rounded, size: 70, color: Tema.marca),
                    ),
                    const SizedBox(height: 24),
                    Text('MediHora', style: Tema.titulo(color: Colors.white, tamano: 40)),
                    const SizedBox(height: 8),
                    Text(
                      'Tu medicina, a tu hora',
                      style: Tema.cuerpo(color: Colors.white.withAlpha(230), tamano: 18),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
