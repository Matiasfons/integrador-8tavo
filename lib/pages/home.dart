import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  bool _isLoading = true;

  // Datos de signos vitales
  Map<String, dynamic> _vitalSigns = {
    'heartRate': 0,
    'bloodPressure': '0/0',
    'oxygenLevel': 0,
    'temperature': 0.0,
  };

  // Datos de actividad física
  Map<String, dynamic> _activityData = {
    'steps': 0,
    'calories': 0,
    'sleep': 0.0,
  };

  // Información del usuario
  String _userName = "Usuario";

  // Referencia a Supabase
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Función para cargar todos los datos del usuario
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Cargar datos del usuario
      await _loadUserProfile(userId);

      // Cargar signos vitales más recientes
      await _loadLatestVitalSigns(userId);

      // Cargar actividad física más reciente
      await _loadLatestActivity(userId);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Cargar datos del perfil del usuario
  Future<void> _loadUserProfile(String userId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).single();

      if (mounted && response != null) {
        setState(() {
          _userName = response['name'] ?? "Usuario";
        });
      }
    } catch (error) {
      // Continuar aunque falle, no es crítico
      print('Error al cargar perfil: $error');
    }
  }

  // Cargar signos vitales más recientes
  Future<void> _loadLatestVitalSigns(String userId) async {
    try {
      final response =
          await _supabase
              .from('vital_signs')
              .select()
              .eq('id_usuario', userId)
              .order('fecha_registro', ascending: false)
              .limit(1)
              .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _vitalSigns = {
            'heartRate': response['frecuencia_cardiaca'] ?? 0,
            'bloodPressure':
                "${response['presion_arterial_sistolica'] ?? 0}/${response['presion_arterial_diastolica'] ?? 0}",
            'oxygenLevel': response['oxigeno_sangre'] ?? 0,
            'temperature': response['temperatura'] ?? 0.0,
          };
        });
      }
    } catch (error) {
      // Continuar aunque falle, no es crítico
      print('Error al cargar signos vitales: $error');
    }
  }

  // Cargar actividad física más reciente
  Future<void> _loadLatestActivity(String userId) async {
    try {
      final response =
          await _supabase
              .from('physical_activity')
              .select()
              .eq('id_usuario', userId)
              .order('fecha_registro', ascending: false)
              .limit(1)
              .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _activityData = {
            'steps': response['pasos'] ?? 0,
            'calories': response['calorias_quemadas'] ?? 0,
            'sleep': response['horas_sueño'] ?? 0.0,
          };
        });
      }
    } catch (error) {
      // Continuar aunque falle, no es crítico
      print('Error al cargar actividad física: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            // Fondo con efecto de partículas (simulado con gradiente)
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  colors: [
                    const Color(0xFF4D80E6).withOpacity(0.15),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),

            // Contenido principal
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4D80E6)),
                )
                : Column(
                  children: [
                    _buildAppBar(),
                    _buildWelcomeHeader(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDashboardTab(),
                          _buildVitalSignsTab(),
                          _buildActivityTab(),
                          _buildProfileTab(),
                        ],
                      ),
                    ),
                  ],
                ),

            // Barra de navegación inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavigation(),
            ),
          ],
        ),
      ),
    );
  }

  // Barra superior con título y opciones
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4D80E6).withOpacity(0.2),
            offset: const Offset(0, 2),
            blurRadius: 4.0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "LEVEL UP TRAINING",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF4D80E6)),
                onPressed: () {
                  _loadUserData(); // Recargar datos
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Color(0xFF4D80E6)),
                onPressed: () {
                  // Navegación a pantalla de configuración
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Encabezado de bienvenida
  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF4D80E6).withOpacity(0.5),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: const Color(0xFF4D80E6), width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4D80E6).withOpacity(0.5),
                  blurRadius: 8.0,
                  spreadRadius: 1.0,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.person, color: Color(0xFF4D80E6), size: 30),
            ),
          ),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Bienvenido, ${_userName.toString().split(" ")[0]}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "¿Cómo te sientes hoy?",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tab de Dashboard con resumen de salud y actividad
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          _buildSectionTitle("RESUMEN DE SALUD"),
          const SizedBox(height: 16.0),

          // Signos vitales en tarjetas
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Frecuencia cardíaca
              _buildVitalSignCard(
                "FRECUENCIA\nCARDÍACA",
                "${_vitalSigns['heartRate']}",
                "bpm",
                const Color(0xFFE63946),
                Icons.favorite,
                "/vital_signs",
              ),

              // Presión arterial
              _buildVitalSignCard(
                "PRESIÓN\nARTERIAL",
                _vitalSigns['bloodPressure'],
                "mmHg",
                const Color(0xFF4D80E6),
                Icons.show_chart,
                "/vital_signs",
              ),

              // Oxígeno en sangre
              _buildVitalSignCard(
                "SATURACIÓN\nOXÍGENO",
                "${_vitalSigns['oxygenLevel']}",
                "%",
                const Color(0xFF9567E0),
                Icons.air,
                "/vital_signs",
              ),

              // Temperatura
              _buildVitalSignCard(
                "TEMPERATURA\nCORPORAL",
                "${_vitalSigns['temperature']}",
                "°C",
                const Color(0xFFFF9E00),
                Icons.thermostat,
                "/vital_signs",
              ),

              // Calculadora IMC
              _buildVitalSignCard(
                "Calculadora\nde IMC",
                "IMC",
                "",
                const Color(0xFF8BC34A),
                Icons.calculate,
                "/imc_calculator",
              ),

              // ChatBot (si lo tienes en la app)
              _buildVitalSignCard(
                "ChatBot Especialista",
                "IA",
                "",
                const Color.fromARGB(255, 36, 154, 217),
                Icons.chat_bubble_outline,
                "/chat-bot",
              ),
            ],
          ),

          const SizedBox(height: 24.0),

          // Título de actividad física
          _buildSectionTitle("ESTADÍSTICAS DE ENTRENAMIENTO"),
          const SizedBox(height: 16.0),

          // Tarjetas de actividad física
          Row(
            children: [
              Expanded(
                child: _buildActivityCard(
                  "PASOS",
                  "${_activityData['steps']}",
                  Icons.directions_walk,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildActivityCard(
                  "CALORÍAS",
                  "${_activityData['calories']}",
                  Icons.local_fire_department,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildActivityCard(
                  "SUEÑO",
                  "${_activityData['sleep']} h",
                  Icons.nightlight_round,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24.0),

          // Tarjetas de acceso rápido a módulos
          _buildSectionTitle("ACCIONES RÁPIDAS"),
          const SizedBox(height: 16.0),

          _buildMissionCard(
            "REGISTRO DIARIO",
            "Registra tus signos vitales para monitorear tu salud",
            const Color(0xFF4D80E6),
            Icons.assignment,
            () {
              Navigator.of(context).pushNamed('/vital_signs');
            },
          ),

          const SizedBox(height: 12.0),

          _buildMissionCard(
            "CONTACTOS DE EMERGENCIA",
            "Añade contactos para casos de emergencia",
            const Color(0xFF9567E0),
            Icons.contact_phone,
            () {
              Navigator.of(context).pushNamed('/emergency_contacts');
            },
          ),

          const SizedBox(height: 12.0),

          _buildMissionCard(
            "SEGUIMIENTO DE ACTIVIDAD",
            "Registra tu actividad física y sueño",
            const Color(0xFFE63946),
            Icons.fitness_center,
            () {
              Navigator.of(context).pushNamed('/physical_activity');
            },
          ),

          // Espacio para compensar la barra de navegación
          const SizedBox(height: 80.0),
        ],
      ),
    );
  }

  // Tab de Signos Vitales
  Widget _buildVitalSignsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite,
            size: 80,
            color: const Color(0xFFE63946).withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            "Módulo de Signos Vitales",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4D80E6),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () {
              Navigator.of(context).pushNamed('/vital_signs');
            },
            child: const Text("REGISTRAR SIGNOS VITALES"),
          ),
        ],
      ),
    );
  }

  // Tab de Actividad Física
  Widget _buildActivityTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: const Color(0xFF9567E0).withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            "Módulo de Actividad Física",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4D80E6),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () {
              Navigator.of(context).pushNamed('/physical_activity');
            },
            child: const Text("VER ESTADÍSTICAS"),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BC34A),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () {
              Navigator.of(context).pushNamed('/imc_calculator');
            },
            child: const Text("CALCULAR IMC"),
          ),
        ],
      ),
    );
  }

  // Tab de Perfil
  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 80,
            color: const Color(0xFF4D80E6).withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            "Perfil de Usuario",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4D80E6),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () {
              // Navegar a la pantalla de edición de perfil
              Navigator.of(context).pushNamed('/edit_profile');
            },
            child: const Text("EDITAR PERFIL"),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9567E0),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () {
              Navigator.of(context).pushNamed('/emergency_contacts');
            },
            child: const Text("CONTACTOS DE EMERGENCIA"),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE63946),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () async {
              final supabase = Supabase.instance.client;
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.pushNamed(context, "/login");
              }
            },
            child: const Text("CERRAR SESIÓN"),
          ),
        ],
      ),
    );
  }

  // Barra de navegación inferior
  Widget _buildBottomNavigation() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4D80E6).withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, "INICIO", Icons.dashboard),
          _buildNavItem(1, "SALUD", Icons.favorite),
          _buildNavItem(2, "ACTIVIDAD", Icons.fitness_center),
          _buildNavItem(3, "PERFIL", Icons.person),
        ],
      ),
    );
  }

  // Ítem de la barra de navegación
  Widget _buildNavItem(int index, String label, IconData icon) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color:
                isSelected
                    ? const Color(0xFF4D80E6)
                    : Colors.white.withOpacity(0.5),
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color:
                  isSelected
                      ? const Color(0xFF4D80E6)
                      : Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF4D80E6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4D80E6).withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Widget para título de sección
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF4D80E6),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4D80E6).withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // Tarjeta para signo vital
  Widget _buildVitalSignCard(
    String title,
    String value,
    String unit,
    Color color,
    IconData icon,
    String url,
  ) {
    return GestureDetector(
      onTap: () {
        if (url.isNotEmpty) {
          Navigator.pushNamed(context, url);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 4)],
              ),
            ),
            Text(
              unit,
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta para actividad física
  Widget _buildActivityCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4D80E6).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF4D80E6), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta para acciones rápidas
  Widget _buildMissionCard(
    String title,
    String description,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
