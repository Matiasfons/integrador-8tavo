import 'package:app_proyecto_integrador/pages/home.dart';
import 'package:app_proyecto_integrador/pages/login.dart';
import 'package:app_proyecto_integrador/pages/register.dart';
import 'package:app_proyecto_integrador/pages/splash.dart';

final routes = {
  "/": (context) => LoginPage(),
  "/register": (context) => RegisterPage(),
  '/splash': (context) => const SplashScreen(),
  "/home":(context)=>const HomePage()
};
