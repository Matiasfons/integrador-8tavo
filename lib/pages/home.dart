import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  
  // Datos de ejemplo para signos vitales
  final Map<String, dynamic> _vitalSigns = {
    'heartRate': 72,
    'bloodPressure': '120/80',
    'oxygenLevel': 98,
    'temperature': 36.5,
  };
  
  // Datos de ejemplo para actividad física
  final Map<String, dynamic> _activityData = {
    'steps': 8456,
    'calories': 420,
    'sleep': 7.5,
    'level': 12,
    'exp': 78, // porcentaje para el siguiente nivel
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            Column(
              children: [
                _buildAppBar(),
                _buildUserStatusBar(),
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
                icon: const Icon(Icons.notifications, color: Color(0xFF4D80E6)),
                onPressed: () {
                  // Navegación a pantalla de notificaciones
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

  // Barra de estado del usuario con nivel y progreso
  Widget _buildUserStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
          // Avatar del usuario con brillo de nivel
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(
                color: const Color(0xFF4D80E6),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4D80E6).withOpacity(0.5),
                  blurRadius: 8.0,
                  spreadRadius: 1.0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                "${_activityData['level']}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          
          // Barra de progreso de nivel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "NIVEL DE CAZADOR",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "${_activityData['exp']}%",
                      style: const TextStyle(
                        color: Color(0xFF4D80E6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Stack(
                  children: [
                    // Fondo de la barra de progreso
                    Container(
                      height: 6.0,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                    ),
                    // Progreso
                    FractionallySizedBox(
                      widthFactor: _activityData['exp'] / 100,
                      child: Container(
                        height: 6.0,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4D80E6), Color(0xFF9567E0)],
                          ),
                          borderRadius: BorderRadius.circular(3.0),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4D80E6).withOpacity(0.5),
                              blurRadius: 4.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                    ElevatedButton(onPressed: ()async{
              final supabase =  Supabase.instance.client;
              await supabase.auth.signOut();
              Navigator.pushNamed(context, "/");
            }, child: Text("Cerrar Sesión")),
              // Frecuencia cardíaca
              _buildVitalSignCard(
                "FRECUENCIA\nCARDÍACA",
                "${_vitalSigns['heartRate']}",
                "bpm",
                const Color(0xFFE63946),
                Icons.favorite,
              ),
              
              // Presión arterial
              _buildVitalSignCard(
                "PRESIÓN\nARTERIAL",
                _vitalSigns['bloodPressure'],
                "mmHg",
                const Color(0xFF4D80E6),
                Icons.show_chart,
              ),
              
              // Oxígeno en sangre
              _buildVitalSignCard(
                "SATURACIÓN\nOXÍGENO",
                "${_vitalSigns['oxygenLevel']}",
                "%",
                const Color(0xFF9567E0),
                Icons.air,
              ),
              
              // Temperatura
              _buildVitalSignCard(
                "TEMPERATURA\nCORPORAL",
                "${_vitalSigns['temperature']}",
                "°C",
                const Color(0xFFFF9E00),
                Icons.thermostat,
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
          _buildSectionTitle("MISIONES ACTIVAS"),
          const SizedBox(height: 16.0),
          
          _buildMissionCard(
            "REGISTRO DIARIO",
            "Registra tus signos vitales para obtener +50 EXP",
            const Color(0xFF4D80E6),
            Icons.assignment,
            () {
              // Navegación a pantalla de registro de signos vitales
            },
          ),
          
          const SizedBox(height: 12.0),
          
          _buildMissionCard(
            "CONTACTOS DE EMERGENCIA",
            "Añade al menos un contacto para +30 EXP",
            const Color(0xFF9567E0),
            Icons.contact_phone,
            () {
              // Navegación a pantalla de contactos
            },
          ),
          
          const SizedBox(height: 12.0),
          
          _buildMissionCard(
            "SEGUIMIENTO DE ACTIVIDAD",
            "Completa 10,000 pasos para +100 EXP",
            const Color(0xFFE63946),
            Icons.fitness_center,
            () {
              // Navegación a pantalla de actividad física
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
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4D80E6),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () {
              // Navegación a pantalla detallada de signos vitales
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
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4D80E6),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () {
              // Navegación a pantalla detallada de actividad física
            },
            child: const Text("VER ESTADÍSTICAS"),
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
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4D80E6),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () {
              // Navegación a pantalla detallada de perfil
            },
            child: const Text("EDITAR PERFIL"),
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
            color: isSelected 
                ? const Color(0xFF4D80E6) 
                : Colors.white.withOpacity(0.5),
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected 
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
  Widget _buildVitalSignCard(String title, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
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
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
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
          Icon(
            icon,
            color: const Color(0xFF4D80E6),
            size: 20,
          ),
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

  // Tarjeta para misiones/tareas
  Widget _buildMissionCard(String title, String description, Color color, IconData icon, VoidCallback onTap) {
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
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
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
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}