import 'package:app_proyecto_integrador/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://pcuikygegkmoqfsuuyzg.supabase.co", 
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjdWlreWdlZ2ttb3Fmc3V1eXpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMyNjE2NzgsImV4cCI6MjA1ODgzNzY3OH0.YbG_XabIy-VwDPrKVA5JgZy0PedF5QGmI121Wx6Fzdc"
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Level Up Training',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212), // Fondo casi negro
        primaryColor: const Color(0xFF4D80E6), // Azul neón estilo Solo Leveling
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4D80E6), // Azul neón principal
          secondary: Color(0xFF9567E0), // Púrpura secundario
          tertiary: Color(0xFFE63946), // Rojo para elementos de peligro/intensidad
          surface: Color(0xFF1E1E1E),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Color(0xFF4D80E6),
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4D80E6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      routes: routes,
      initialRoute: '/splash', // Asegúrate de tener esta ruta definida
      debugShowCheckedModeBanner: false,
    );
  }
}