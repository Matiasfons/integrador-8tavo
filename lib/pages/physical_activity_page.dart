import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PhysicalActivityPage extends StatefulWidget {
  const PhysicalActivityPage({super.key});

  @override
  State<PhysicalActivityPage> createState() => _PhysicalActivityPageState();
}

class _PhysicalActivityPageState extends State<PhysicalActivityPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSubmitting = false;
  late TabController _tabController;
  
  // Controllers para los campos
  final _stepsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _sleepController = TextEditingController();
  
  // Datos históricos
  List<Map<String, dynamic>> _activityHistory = [];
  
  // Resumen de actividad
  int _totalSteps = 0;
  double _avgSteps = 0;
  double _avgSleep = 0;
  double _avgCalories = 0;
  
  // Referencia a Supabase
  final _supabase = Supabase.instance.client;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadActivityData();
  }
  
  @override
  void dispose() {
    _stepsController.dispose();
    _caloriesController.dispose();
    _sleepController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  // Función para cargar datos de actividad física
  Future<void> _loadActivityData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }
      
      // Obtener registros de actividad física ordenados por fecha
      final response = await _supabase
          .from('physical_activity')
          .select()
          .eq('id_usuario', userId)
          .order('fecha_registro', ascending: false);
      
      final List<Map<String, dynamic>> activityList = List<Map<String, dynamic>>.from(response);
      
      if (mounted) {
        setState(() {
          _activityHistory = activityList;
          
          // Procesar datos para gráficos y resumen
          _processActivityData(activityList);
          
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
  
  // Procesa los datos de actividad para los gráficos y resumen
  void _processActivityData(List<Map<String, dynamic>> activityList) {
    if (activityList.isEmpty) return;
    
    int totalSteps = 0;
    double totalSleep = 0;
    double totalCalories = 0;
    
    // Calcular totales y promedios
    for (final record in activityList) {
      totalSteps += (record['pasos'] ?? 0) as int;
      totalSleep += record['horas_sueño'] ?? 0;
      totalCalories += record['calorias_quemadas'] ?? 0;
    }
    
    setState(() {
      _totalSteps = totalSteps;
      _avgSteps = activityList.isNotEmpty ? totalSteps / activityList.length : 0;
      _avgSleep = activityList.isNotEmpty ? totalSleep / activityList.length : 0;
      _avgCalories = activityList.isNotEmpty ? totalCalories / activityList.length : 0;
    });
  }
  
  // Función para registrar nueva actividad
  Future<void> _submitActivity() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }
      
      // Datos a insertar
      final activityData = {
        'id_usuario': userId,
        'pasos': int.parse(_stepsController.text.trim()),
        'calorias_quemadas': double.parse(_caloriesController.text.trim()),
        'horas_sueño': double.parse(_sleepController.text.trim()),
      };
      
      // Insertar en la base de datos
      await _supabase
          .from('physical_activity')
          .insert(activityData);
      
      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actividad registrada con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar formulario
        _stepsController.clear();
        _caloriesController.clear();
        _sleepController.clear();
        
        // Recargar datos
        _loadActivityData();
        
        // Cambiar a la pestaña de estadísticas
        _tabController.animateTo(1);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar actividad: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          "ACTIVIDAD FÍSICA",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: const Color(0xFF4D80E6).withOpacity(0.8),
                blurRadius: 5,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF4D80E6),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4D80E6),
          labelColor: const Color(0xFF4D80E6),
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: "REGISTRAR", icon: Icon(Icons.add_circle_outline)),
            Tab(text: "HISTORIAL", icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          image: DecorationImage(
            image: const AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.85),
              BlendMode.darken,
            ),
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildRegisterTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }
  
  // Tab de registro de actividad
  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            
            // Campo de pasos
            _buildActivityField(
              "Pasos Diarios",
              "pasos",
              _stepsController,
              Icons.directions_walk,
              const Color(0xFF4D80E6),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el número de pasos';
                }
                try {
                  final steps = int.parse(value);
                  if (steps < 0 || steps > 100000) {
                    return 'El valor debe estar entre 0 y 100,000';
                  }
                } catch (e) {
                  return 'Ingresa un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Campo de calorías
            _buildActivityField(
              "Calorías Quemadas",
              "kcal",
              _caloriesController,
              Icons.local_fire_department,
              const Color(0xFFE63946),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa las calorías quemadas';
                }
                try {
                  final calories = double.parse(value);
                  if (calories < 0 || calories > 10000) {
                    return 'El valor debe estar entre 0 y 10,000';
                  }
                } catch (e) {
                  return 'Ingresa un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Campo de sueño
            _buildActivityField(
              "Horas de Sueño",
              "horas",
              _sleepController,
              Icons.nightlight_round,
              const Color(0xFF9567E0),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa las horas de sueño';
                }
                try {
                  final sleep = double.parse(value);
                  if (sleep < 0 || sleep > 24) {
                    return 'El valor debe estar entre 0 y 24';
                  }
                } catch (e) {
                  return 'Ingresa un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            
            // Botón de guardar
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitActivity,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D80E6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 5,
                shadowColor: const Color(0xFF4D80E6).withOpacity(0.5),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'REGISTRAR ACTIVIDAD',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Tab de historial
  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4D80E6),
        ),
      );
    }
    
    if (_activityHistory.isEmpty) {
      return _buildEmptyStateMessage(
        "No hay registros de actividad",
        "Registra tu actividad física diaria para empezar tu seguimiento",
        Icons.fitness_center,
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen de actividad
          _buildSectionTitle("RESUMEN DE ACTIVIDAD"),
          const SizedBox(height: 16),
          
          // Tarjetas de estadísticas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "TOTAL PASOS",
                  _totalSteps.toString(),
                  Icons.directions_walk,
                  const Color(0xFF4D80E6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  "PROMEDIO\nPASOS",
                  _avgSteps.toStringAsFixed(0),
                  Icons.trending_up,
                  const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "PROMEDIO\nSUEÑO",
                  "${_avgSleep.toStringAsFixed(1)} h",
                  Icons.nightlight_round,
                  const Color(0xFF9567E0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  "PROMEDIO\nCALORÍAS",
                  "${_avgCalories.toStringAsFixed(0)} kcal",
                  Icons.local_fire_department,
                  const Color(0xFFE63946),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Lista de registros históricos
          _buildSectionTitle("HISTORIAL DE ACTIVIDAD"),
          const SizedBox(height: 16),
          
          ..._activityHistory.map((record) => _buildHistoryCard(record)).toList(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  // Tarjeta para cada registro histórico
  Widget _buildHistoryCard(Map<String, dynamic> record) {
    final date = DateTime.parse(record['fecha_registro']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF4D80E6).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(date),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(
              color: Color(0xFF4D80E6),
              thickness: 1,
              height: 24,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHistoryItem(
                  "Pasos",
                  "${record['pasos']}",
                  Icons.directions_walk,
                  const Color(0xFF4D80E6),
                ),
                _buildHistoryItem(
                  "Calorías",
                  "${record['calorias_quemadas']} kcal",
                  Icons.local_fire_department,
                  const Color(0xFFE63946),
                ),
                _buildHistoryItem(
                  "Sueño",
                  "${record['horas_sueño']} h",
                  Icons.nightlight_round,
                  const Color(0xFF9567E0),
                ),
              ],
            ),
            // Barra de progresión de pasos hacia la meta
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "PROGRESO HACIA 10,000 PASOS",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${((record['pasos'] / 10000) * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(
                        color: Color(0xFF4D80E6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    // Fondo de la barra de progreso
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Progreso
                    FractionallySizedBox(
                      widthFactor: (record['pasos'] / 10000).clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4D80E6),
                              Color(0xFF9567E0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4D80E6).withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget para mostrar mensaje de estado vacío
  Widget _buildEmptyStateMessage(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: const Color(0xFF4D80E6).withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D80E6),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _tabController.animateTo(0);
              },
              child: const Text("REGISTRAR AHORA"),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget para el encabezado
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4D80E6).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4D80E6).withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4D80E6).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF4D80E6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4D80E6).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 32,
                  color: Color(0xFF4D80E6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "REGISTRO DE ACTIVIDAD",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF4D80E6).withOpacity(0.8),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Registra tu actividad física y horas de sueño diarias",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "El seguimiento regular ayuda a mejorar tus hábitos y optimizar tu rendimiento",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // Widget para campo de actividad
  Widget _buildActivityField(
    String label,
    String unit,
    TextEditingController controller,
    IconData icon,
    Color color, {
    required FormFieldValidator<String> validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  unit,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "Ingresa el valor",
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
                errorStyle: TextStyle(
                  color: Colors.red[300],
                  fontWeight: FontWeight.normal,
                ),
              ),
              validator: validator,
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget para mostrar ítem del historial
  Widget _buildHistoryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: color.withOpacity(0.5),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
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
  
  // Widget para tarjeta de estadísticas
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}