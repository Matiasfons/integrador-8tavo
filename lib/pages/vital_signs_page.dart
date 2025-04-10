import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class VitalSignsPage extends StatefulWidget {
  const VitalSignsPage({super.key});

  @override
  State<VitalSignsPage> createState() => _VitalSignsPageState();
}

class _VitalSignsPageState extends State<VitalSignsPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSubmitting = false;
  late TabController _tabController;
  
  // Controllers para los campos
  final _heartRateController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _oxygenController = TextEditingController();
  final _temperatureController = TextEditingController();
  
  // Datos históricos
  List<Map<String, dynamic>> _vitalSignsHistory = [];
  bool _isLoadingHistory = true;
  
  // Referencia a Supabase
  final _supabase = Supabase.instance.client;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVitalSignsHistory();
  }
  
  @override
  void dispose() {
    _heartRateController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _oxygenController.dispose();
    _temperatureController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  // Función para cargar el historial de signos vitales
  Future<void> _loadVitalSignsHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }
      
      // Obtener registros de signos vitales ordenados por fecha
      final response = await _supabase
          .from('vital_signs')
          .select()
          .eq('id_usuario', userId)
          .order('fecha_registro', ascending: false)
          .limit(10);
      
      if (mounted) {
        setState(() {
          _vitalSignsHistory = List<Map<String, dynamic>>.from(response);
          _isLoadingHistory = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar historial: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Función para registrar nuevos signos vitales
  Future<void> _submitVitalSigns() async {
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
      final vitalSignsData = {
        'id_usuario': userId,
        'frecuencia_cardiaca': int.parse(_heartRateController.text.trim()),
        'presion_arterial_sistolica': int.parse(_systolicController.text.trim()),
        'presion_arterial_diastolica': int.parse(_diastolicController.text.trim()),
        'oxigeno_sangre': double.parse(_oxygenController.text.trim()),
        'temperatura': double.parse(_temperatureController.text.trim()),
      };
      
      // Insertar en la base de datos
      await _supabase
          .from('vital_signs')
          .insert(vitalSignsData);
      
      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signos vitales registrados con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar formulario
        _heartRateController.clear();
        _systolicController.clear();
        _diastolicController.clear();
        _oxygenController.clear();
        _temperatureController.clear();
        
        // Recargar historial
        _loadVitalSignsHistory();
        
        // Cambiar a la pestaña de historial
        _tabController.animateTo(1);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar signos vitales: ${error.toString()}'),
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
          "SIGNOS VITALES",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: const Color(0xFFE63946).withOpacity(0.8),
                blurRadius: 5,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFFE63946),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE63946),
          labelColor: const Color(0xFFE63946),
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
  
  // Tab de registro de signos vitales
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
            
            // Frecuencia cardíaca
            _buildVitalSignField(
              "Frecuencia Cardíaca",
              "BPM",
              _heartRateController,
              Icons.favorite,
              const Color(0xFFE63946),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa la frecuencia cardíaca';
                }
                try {
                  final hr = int.parse(value);
                  if (hr < 40 || hr > 200) {
                    return 'El valor debe estar entre 40 y 200';
                  }
                } catch (e) {
                  return 'Ingresa un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Presión arterial
            Row(
              children: [
                Expanded(
                  child: _buildVitalSignField(
                    "Sistólica",
                    "mmHg",
                    _systolicController,
                    Icons.show_chart,
                    const Color(0xFF4D80E6),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      try {
                        final sys = int.parse(value);
                        if (sys < 70 || sys > 220) {
                          return '70-220 mmHg';
                        }
                      } catch (e) {
                        return 'Número inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildVitalSignField(
                    "Diastólica",
                    "mmHg",
                    _diastolicController,
                    Icons.show_chart,
                    const Color(0xFF4D80E6),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      try {
                        final dia = int.parse(value);
                        if (dia < 40 || dia > 130) {
                          return '40-130 mmHg';
                        }
                      } catch (e) {
                        return 'Número inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Saturación de oxígeno
            _buildVitalSignField(
              "Saturación de Oxígeno",
              "%",
              _oxygenController,
              Icons.air,
              const Color(0xFF9567E0),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa la saturación de oxígeno';
                }
                try {
                  final oxygen = double.parse(value);
                  if (oxygen < 80 || oxygen > 100) {
                    return 'El valor debe estar entre 80 y 100';
                  }
                } catch (e) {
                  return 'Ingresa un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Temperatura
            _buildVitalSignField(
              "Temperatura",
              "°C",
              _temperatureController,
              Icons.thermostat,
              const Color(0xFFFF9E00),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa la temperatura';
                }
                try {
                  final temp = double.parse(value);
                  if (temp < 35 || temp > 42) {
                    return 'El valor debe estar entre 35 y 42';
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
              onPressed: _isSubmitting ? null : _submitVitalSigns,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE63946),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 5,
                shadowColor: const Color(0xFFE63946).withOpacity(0.5),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'REGISTRAR SIGNOS VITALES',
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
  
  // Tab de historial de signos vitales
  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE63946),
        ),
      );
    }
    
    if (_vitalSignsHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 80,
                color: const Color(0xFFE63946).withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              const Text(
                "No hay registros de signos vitales",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Registra tus primeros signos vitales para empezar a monitorear tu salud",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE63946),
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
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vitalSignsHistory.length,
      itemBuilder: (context, index) {
        final record = _vitalSignsHistory[index];
        final date = DateTime.parse(record['fecha_registro']);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: const Color(0xFFE63946).withOpacity(0.3),
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
                  color: Color(0xFFE63946),
                  thickness: 1,
                  height: 24,
                ),
                Row(
                  children: [
                    _buildHistoryItem(
                      "Frecuencia\nCardíaca",
                      "${record['frecuencia_cardiaca']} bpm",
                      Icons.favorite,
                      const Color(0xFFE63946),
                    ),
                    _buildHistoryItem(
                      "Presión\nArterial",
                      "${record['presion_arterial_sistolica']}/${record['presion_arterial_diastolica']} mmHg",
                      Icons.show_chart,
                      const Color(0xFF4D80E6),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildHistoryItem(
                      "Saturación\nOxígeno",
                      "${record['oxigeno_sangre']}%",
                      Icons.air,
                      const Color(0xFF9567E0),
                    ),
                    _buildHistoryItem(
                      "Temperatura\nCorporal",
                      "${record['temperatura']}°C",
                      Icons.thermostat,
                      const Color(0xFFFF9E00),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Widget para el encabezado de registro
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE63946).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE63946).withOpacity(0.2),
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
                  color: const Color(0xFFE63946).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE63946),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE63946).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 32,
                  color: Color(0xFFE63946),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "REGISTRO DIARIO",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFE63946).withOpacity(0.8),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Ingresa tus signos vitales para monitorear tu salud",
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
            "Los valores fuera de rango normal serán marcados automáticamente para alertar sobre posibles problemas de salud",
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
  
  // Widget para campo de signos vitales
  Widget _buildVitalSignField(
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
        padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}