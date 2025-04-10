import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ImcCalculatorPage extends StatefulWidget {
  const ImcCalculatorPage({super.key});

  @override
  State<ImcCalculatorPage> createState() => _ImcCalculatorPageState();
}

class _ImcCalculatorPageState extends State<ImcCalculatorPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasCalculated = false;
  late TabController _tabController;
  
  // Controllers para los campos
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  // Resultados del IMC
  double _imcResult = 0.0;
  String _imcCategory = "";
  Color _imcColor = Colors.grey;
  
  // Historial de IMC
  List<Map<String, dynamic>> _imcHistory = [];
  
  // Referencia a Supabase
  final _supabase = Supabase.instance.client;
  
  // Categorías de IMC
  final Map<String, Map<String, dynamic>> _imcCategories = {
    'Bajo peso severo': {'min': 0, 'max': 16.0, 'color': const Color(0xFF2196F3)},
    'Bajo peso': {'min': 16.0, 'max': 18.5, 'color': const Color(0xFF4CAF50)},
    'Normal': {'min': 18.5, 'max': 25.0, 'color': const Color(0xFF8BC34A)},
    'Sobrepeso': {'min': 25.0, 'max': 30.0, 'color': const Color(0xFFFFC107)},
    'Obesidad grado I': {'min': 30.0, 'max': 35.0, 'color': const Color(0xFFFF9800)},
    'Obesidad grado II': {'min': 35.0, 'max': 40.0, 'color': const Color(0xFFFF5722)},
    'Obesidad grado III': {'min': 40.0, 'max': double.infinity, 'color': const Color(0xFFE63946)},
  };
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadImcHistory();
  }
  
  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  // Función para cargar historial de IMC
  Future<void> _loadImcHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }
      
      // Obtener registros de IMC ordenados por fecha
      final response = await _supabase
          .from('imc_records')
          .select()
          .eq('id_usuario', userId)
          .order('fecha_registro', ascending: false);
      
      if (mounted) {
        setState(() {
          _imcHistory = List<Map<String, dynamic>>.from(response);
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
            content: Text('Error al cargar historial: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Función para calcular el IMC - CORREGIDA
  void _calculateImc() {
    if (!_formKey.currentState!.validate()) return;
    
    final weight = double.parse(_weightController.text.trim());
    final height = double.parse(_heightController.text.trim()) / 100; // Convertir a metros
    
    // Fórmula IMC = peso(kg) / altura²(m)
    final imc = weight / (height * height);
    
    // Determinar categoría - CORREGIDO para asegurar que siempre se asigne una categoría
    String category = "Obesidad grado III"; // Valor por defecto
    Color color = _imcCategories['Obesidad grado III']!['color'] as Color;
    
    for (final entry in _imcCategories.entries) {
      final min = entry.value['min'] ;
      final max = entry.value['max'] ;
      
      if (imc >= min && imc < max) {
        category = entry.key;
        color = entry.value['color'] as Color;
        break;
      }
    }
    
    setState(() {
      _imcResult = imc;
      _imcCategory = category;
      _imcColor = color;
      _hasCalculated = true;
    });
  }
  
  // Función para guardar el IMC en la base de datos
  Future<void> _saveImc() async {
    if (!_hasCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero debes calcular tu IMC'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }
      
      // Datos a insertar
      final imcData = {
        'id_usuario': userId,
        'peso': double.parse(_weightController.text.trim()),
        'altura': double.parse(_heightController.text.trim()),
        'imc': _imcResult,
        'clasificacion': _imcCategory,
      };
      
      // Insertar en la base de datos
      await _supabase
          .from('imc_records')
          .insert(imcData);
      
      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('IMC registrado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recargar historial
        _loadImcHistory();
        
        // Cambiar a la pestaña de historial
        _tabController.animateTo(1);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar IMC: ${error.toString()}'),
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
          "CALCULADORA IMC",
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
            Tab(text: "CALCULAR", icon: Icon(Icons.calculate)),
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
            _buildCalculatorTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }
  
  // Tab de calculadora - CORREGIDO para resolver overflow
  Widget _buildCalculatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            
            // Campo de peso
            _buildImcField(
              "Peso",
              "kg",
              _weightController,
              Icons.monitor_weight,
              const Color(0xFF4D80E6),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu peso';
                }
                try {
                  final weight = double.parse(value);
                  if (weight <= 0 || weight > 300) {
                    return 'Ingresa un peso válido (1-300 kg)';
                  }
                } catch (e) {
                  return 'Ingresa un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Campo de altura
            _buildImcField(
              "Altura",
              "cm",
              _heightController,
              Icons.height,
              const Color(0xFF9567E0),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu altura';
                }
                try {
                  final height = double.parse(value);
                  if (height <= 0 || height > 250) {
                    return 'Ingresa una altura válida (1-250 cm)';
                  }
                } catch (e) {
                  return 'Ingresa un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Botón de calcular
            ElevatedButton(
              onPressed: _calculateImc,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D80E6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 5,
                shadowColor: const Color(0xFF4D80E6).withOpacity(0.5),
              ),
              child: Text(
                'CALCULAR IMC',
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
            const SizedBox(height: 24),
            
            // Resultados - CORREGIDO para evitar overflow
            if (_hasCalculated) _buildImcResult(),
            
            if (_hasCalculated)
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveImc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BC34A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFF8BC34A).withOpacity(0.5),
                    disabledBackgroundColor: const Color(0xFF8BC34A).withOpacity(0.4),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : Text(
                          'GUARDAR RESULTADO',
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
              ),
            
            const SizedBox(height: 16),
            
            // Tabla de referencias - CORREGIDA para mejor visualización
            _buildReferenceTable(),
            
            // Espacio adicional al final para evitar overflow con teclado
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  // Tab de historial - CORREGIDO para resolver problemas de overflow
  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4D80E6),
        ),
      );
    }
    
    if (_imcHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calculate,
                size: 80,
                color: const Color(0xFF4D80E6).withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              const Text(
                "No hay registros de IMC",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Calcula tu IMC para empezar a monitorear tu peso",
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
                child: const Text("CALCULAR AHORA"),
              ),
            ],
          ),
        ),
      );
    }
    
    // CORREGIDO: Usando ListView.builder con physics para permitir scroll
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _imcHistory.length,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final record = _imcHistory[index];
        final date = DateTime.parse(record['fecha_registro']);
        final category = record['clasificacion'];
        final imc = record['imc'].toDouble();
        final weight = record['peso'].toDouble();
        final height = record['altura'].toDouble();
        
        // Determinar color según categoría
        Color categoryColor = Colors.grey;
        for (final entry in _imcCategories.entries) {
          if (entry.key == category) {
            categoryColor = entry.value['color'];
            break;
          }
        }
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: categoryColor.withOpacity(0.5),
              width: 1.5,
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
                // CORREGIDO: Diseño más adaptable para evitar overflows
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Círculo de resultado - reducido tamaño para evitar overflow
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          border: Border.all(
                            color: categoryColor,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: categoryColor.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                imc.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  shadows: [
                                    Shadow(
                                      color: categoryColor.withOpacity(0.8),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "IMC",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Información detallada
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.monitor_weight,
                                  color: Color(0xFF4D80E6),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Peso: $weight kg",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.height,
                                  color: Color(0xFF9567E0),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Altura: $height cm",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: categoryColor,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: TextStyle(
                                  color: categoryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Mensaje de recomendación - CORREGIDO para ajustar mejor al espacio
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: categoryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: categoryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getRecommendationText(category),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Widget para mostrar resultado de IMC - CORREGIDO para evitar overflow
  Widget _buildImcResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _imcColor.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _imcColor.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "TU RESULTADO",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // CORREGIDO: Layout más flexible y adaptable
          LayoutBuilder(
            builder: (context, constraints) {
              // Adaptamos el diseño según el ancho disponible
              final useRow = constraints.maxWidth > 300;
              return useRow 
                ? _buildHorizontalResultLayout()
                : _buildVerticalResultLayout();
            }
          ),
        ],
      ),
    );
  }
  
  // Layout horizontal para resultados (pantallas más anchas)
  Widget _buildHorizontalResultLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Círculo de resultado
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(
              color: _imcColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _imcColor.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _imcResult.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    shadows: [
                      Shadow(
                        color: _imcColor.withOpacity(0.8),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Text(
                  "IMC",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _imcCategory.toUpperCase(),
                style: TextStyle(
                  color: _imcColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: _imcColor.withOpacity(0.8),
                      blurRadius: 4,
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 8),
              Text(
                _getRecommendationText(_imcCategory),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Layout vertical para resultados (pantallas más estrechas)
  Widget _buildVerticalResultLayout() {
    return Column(
      children: [
        // Círculo de resultado
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(
              color: _imcColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _imcColor.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _imcResult.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    shadows: [
                      Shadow(
                        color: _imcColor.withOpacity(0.8),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Text(
                  "IMC",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _imcCategory.toUpperCase(),
          style: TextStyle(
            color: _imcColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: _imcColor.withOpacity(0.8),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _getRecommendationText(_imcCategory),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  // Widget para tabla de referencia - CORREGIDO para mejor visualización
  Widget _buildReferenceTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "REFERENCIA DE IMC",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
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
          const SizedBox(height: 12),
          const Divider(color: Colors.white30),
          ..._imcCategories.entries.map((entry) {
            final category = entry.key;
            final min = entry.value['min'];
            final max = entry.value['max'];
            final range = max == double.infinity 
                ? ">= $min" 
                : "$min - $max";
            final color = entry.value['color'];
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      range,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  // Widget para el encabezado - MEJORADO para mejor visualización
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
                  Icons.calculate,
                  size: 28,
                  color: Color(0xFF4D80E6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ÍNDICE DE MASA CORPORAL",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF4D80E6).withOpacity(0.8),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Calcula tu IMC para monitorear tu peso saludable",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "IMC = Peso (kg) / Altura² (m²)",
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
  
  // Widget para campo de IMC - MEJORADO para mejor validación
  Widget _buildImcField(
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
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
                  fontSize: 12,
                ),
                // Agregamos un espacio para el error
                errorMaxLines: 2,
              ),
              validator: validator,
            ),
          ],
        ),
      ),
    );
  }
  
  // Función para obtener recomendación según categoría
  String _getRecommendationText(String category) {
    switch (category) {
      case 'Bajo peso severo':
        return "Es importante consultar a un profesional de la salud para evaluar causas y desarrollar un plan nutricional.";
      case 'Bajo peso':
        return "Considera aumentar la ingesta calórica con alimentos nutritivos y consultar a un nutricionista.";
      case 'Normal':
        return "¡Excelente! Mantén hábitos saludables de alimentación y actividad física regular.";
      case 'Sobrepeso':
        return "Considera ajustar tu dieta e incrementar la actividad física. Consulta a un profesional para un plan personalizado.";
      case 'Obesidad grado I':
        return "Recomendable buscar asesoría médica para un plan de pérdida de peso gradual y saludable.";
      case 'Obesidad grado II':
        return "Importante consultar a un profesional de la salud para un plan de manejo integral del peso.";
      case 'Obesidad grado III':
        return "Requiere atención médica prioritaria para evaluar riesgos y desarrollar un plan de tratamiento.";
      default:
        return "Consulta a un profesional de la salud para una evaluación completa.";
    }
  }
}