import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSubmitting = false;
  late TabController _tabController;
  
  // Controllers para los campos
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();
  
  // Lista de contactos
  List<Map<String, dynamic>> _contacts = [];
  
  // Referencia a Supabase
  final _supabase = Supabase.instance.client;
  
  // Relaciones predefinidas
  final List<String> _relationOptions = [
    'Familiar',
    'Amigo/a',
    'Médico',
    'Vecino/a',
    'Compañero/a de trabajo',
    'Otro'
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContacts();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  // Función para cargar los contactos
  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }
      
      // Obtener contactos de emergencia
      final response = await _supabase
          .from('emergency_contacts')
          .select()
          .eq('id_usuario', userId)
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _contacts = List<Map<String, dynamic>>.from(response);
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
            content: Text('Error al cargar contactos: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Función para agregar un nuevo contacto
  Future<void> _addContact() async {
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
      final contactData = {
        'id_usuario': userId,
        'nombre': _nameController.text.trim(),
        'telefono': _phoneController.text.trim(),
        'relacion': _relationController.text.trim(),
      };
      
      // Insertar en la base de datos
      await _supabase
          .from('emergency_contacts')
          .insert(contactData);
      
      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contacto agregado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar formulario
        _nameController.clear();
        _phoneController.clear();
        _relationController.clear();
        
        // Recargar contactos
        _loadContacts();
        
        // Cambiar a la pestaña de contactos
        _tabController.animateTo(1);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar contacto: ${error.toString()}'),
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
  
  // Función para eliminar un contacto
  Future<void> _deleteContact(String contactId) async {
    try {
      await _supabase
          .from('emergency_contacts')
          .delete()
          .eq('id_contacto', contactId);
      
      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contacto eliminado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recargar contactos
        _loadContacts();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar contacto: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Función para llamar a un contacto
  Future<void> _callContact(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'No se pudo realizar la llamada';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al realizar llamada: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Función para enviar un mensaje a un contacto
  Future<void> _messageContact(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        throw 'No se pudo enviar el mensaje';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          "CONTACTOS DE EMERGENCIA",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: const Color(0xFF9567E0).withOpacity(0.8),
                blurRadius: 5,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF9567E0),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF9567E0),
          labelColor: const Color(0xFF9567E0),
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: "AGREGAR", icon: Icon(Icons.person_add)),
            Tab(text: "CONTACTOS", icon: Icon(Icons.contacts)),
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
            _buildAddContactTab(),
            _buildContactsListTab(),
          ],
        ),
      ),
    );
  }
  
  // Tab para agregar contacto
  Widget _buildAddContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            
            // Campo de nombre
            TextFormField(
              controller: _nameController,
              decoration: _buildInputDecoration("Nombre del Contacto", Icons.person),
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el nombre del contacto';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Campo de teléfono
            TextFormField(
              controller: _phoneController,
              decoration: _buildInputDecoration("Número de Teléfono", Icons.phone),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el número de teléfono';
                }
                if (value.length < 8) {
                  return 'Ingresa un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Campo de relación
            DropdownButtonFormField<String>(
              decoration: _buildInputDecoration("Relación", Icons.people),
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white),
              hint: Text(
                "Selecciona la relación",
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              items: _relationOptions.map((String relation) {
                return DropdownMenuItem<String>(
                  value: relation,
                  child: Text(relation),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _relationController.text = newValue;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor selecciona la relación';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            
            // Botón de guardar
            ElevatedButton(
              onPressed: _isSubmitting ? null : _addContact,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9567E0),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 5,
                shadowColor: const Color(0xFF9567E0).withOpacity(0.5),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'GUARDAR CONTACTO',
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
  
  // Tab para lista de contactos
  Widget _buildContactsListTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF9567E0),
        ),
      );
    }
    
    if (_contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.contacts,
                size: 80,
                color: const Color(0xFF9567E0).withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              const Text(
                "No tienes contactos de emergencia",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Agrega contactos para que puedan ser notificados en caso de emergencia",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9567E0),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  _tabController.animateTo(0);
                },
                child: const Text("AGREGAR CONTACTO"),
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: const Color(0xFF9567E0).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF9567E0).withOpacity(0.2),
                      child: Text(
                        contact['nombre'].substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF9567E0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact['nombre'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                color: Color(0xFF9567E0),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                contact['telefono'],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (contact['relacion'] != null && contact['relacion'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                contact['relacion'],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () {
                        _showDeleteConfirmationDialog(contact['id_contacto']);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildContactActionButton(
                      "LLAMAR",
                      Icons.call,
                      const Color(0xFF4CAF50),
                      () => _callContact(contact['telefono']),
                    ),
                    _buildContactActionButton(
                      "MENSAJE",
                      Icons.message,
                      const Color(0xFF2196F3),
                      () => _messageContact(contact['telefono']),
                    ),
                    _buildContactActionButton(
                      "COPIAR",
                      Icons.content_copy,
                      const Color(0xFFFF9800),
                      () {
                        Clipboard.setData(ClipboardData(text: contact['telefono']));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Número copiado al portapapeles'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
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
  
  // Widget para el encabezado
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9567E0).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9567E0).withOpacity(0.2),
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
                  color: const Color(0xFF9567E0).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF9567E0),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9567E0).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.contact_phone,
                  size: 32,
                  color: Color(0xFF9567E0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AGREGAR CONTACTO",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF9567E0).withOpacity(0.8),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Añade personas que puedan ser contactadas en caso de emergencia",
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
            "Los contactos recibirán notificaciones cuando tus signos vitales estén fuera de los rangos normales",
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
  
  // Función auxiliar para crear decoraciones de input consistentes
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF9567E0)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.black.withOpacity(0.7),
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: const Color(0xFF9567E0).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF9567E0),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: const Color(0xFFE63946),
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFFE63946),
          width: 2,
        ),
      ),
    );
  }
  
  // Widget para botones de acción de contacto
  Widget _buildContactActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.5), width: 1),
        ),
      ),
    );
  }
  
  // Diálogo de confirmación para eliminar contacto
  void _showDeleteConfirmationDialog(String contactId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Eliminar Contacto",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "¿Estás seguro de que deseas eliminar este contacto? Esta acción no se puede deshacer.",
          style: TextStyle(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              "CANCELAR",
              style: TextStyle(
                color: Color(0xFF9567E0),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteContact(contactId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("ELIMINAR"),
          ),
        ],
      ),
    );
  }
}