import 'package:app_proyecto_integrador/pages/chatBot.dart';
import 'package:app_proyecto_integrador/pages/edit_profile.dart';
import 'package:app_proyecto_integrador/pages/emergency_contacts_page.dart';
import 'package:app_proyecto_integrador/pages/home.dart';
import 'package:app_proyecto_integrador/pages/imc_calculator_page.dart';
import 'package:app_proyecto_integrador/pages/login.dart';
import 'package:app_proyecto_integrador/pages/physical_activity_page.dart';
import 'package:app_proyecto_integrador/pages/register.dart';
import 'package:app_proyecto_integrador/pages/splash.dart';
import 'package:app_proyecto_integrador/pages/vital_signs_page.dart';

final routes = {
  "/": (context) => LoginPage(),
  "/register": (context) => RegisterPage(),
  '/splash': (context) => const SplashScreen(),
  "/home": (context) => const HomePage(),
  "/chat-bot": (context) => ChatBot(),
  '/edit_profile': (context) => const EditProfilePage(),
    '/vital_signs': (context) => const VitalSignsPage(),
  '/emergency_contacts': (context) => const EmergencyContactsPage(),
  '/physical_activity': (context) => const PhysicalActivityPage(),
  '/imc_calculator': (context) => const ImcCalculatorPage(),
};
