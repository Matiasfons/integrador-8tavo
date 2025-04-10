import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isDataLoaded = false;
  bool _showPasswordSection = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  // Controllers para los campos
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Variables para fecha y género
  DateTime? _birthDate;
  String _gender = 'Masculino'; // Valor predeterminado
  final List<String> _genderOptions = ['Masculino', 'Femenino', 'Otro', 'Prefiero no decir'];
  
  // Referencia a Supabase
  final _supabase = Supabase.instance.client;
  
  @override
  void initState() {
    super.initState();
    // Cargar datos del usuario
    _loadUserData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  // Función para cargar los datos del usuario
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Obtener el ID del usuario actual
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }
      
      // Obtener los datos del usuario desde Supabase
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      
      if (mounted) {
        setState(() {
          // Llenar los controladores con los datos
          _nameController.text = response['name'] ?? '';
          _emailController.text = response['email'] ?? '';
          _phoneController.text = response['phone'] ?? '';
          
          // Convertir la fecha de nacimiento
          if (response['birthdate'] != null) {
            _birthDate = DateTime.parse(response['birthdate']);
          }
          
          // Establecer el género
          if (response['gender'] != null) {
            _gender = response['gender'];
          }
          
          _isDataLoaded = true;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Mostrar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar los datos: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Función para seleccionar fecha de nacimiento
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1923),
      lastDate: DateTime(now.year - 13, now.month, now.day), // Mínimo 13 años
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4D80E6),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4D80E6),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }
  
  // Función para guardar los cambios
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Obtener el ID del usuario actual
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }
      
      // Datos a actualizar
      final updatedData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _gender,
      };
      
      // Agregar fecha de nacimiento si está definida
      if (_birthDate != null) {
        updatedData['birthdate'] = DateFormat('yyyy-MM-dd').format(_birthDate!);
      }
      
      // Actualizar datos en la base de datos
      await _supabase
          .from('users')
          .update(updatedData)
          .eq('id', userId);
      
      // Actualizar email si es necesario (esto requiere una operación separada)
      final currentUser = _supabase.auth.currentUser;
      if (currentUser?.email != _emailController.text.trim()) {
        await _supabase.auth.updateUser(
          UserAttributes(
            email: _emailController.text.trim(),
          ),
        );
      }
      
      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navegar hacia atrás
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        // Mostrar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el perfil: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Función para cambiar la contraseña
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    
    // Verificar que la nueva contraseña y la confirmación coincidan
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Actualizar contraseña usando Supabase Auth
      await _supabase.auth.updateUser(
        UserAttributes(
          password: _newPasswordController.text,
        ),
      );
      
      if (mounted) {
        // Limpiar campos de contraseña
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Ocultar sección de contraseña
        setState(() {
          _showPasswordSection = false;
        });
      }
    } catch (error) {
      if (mounted) {
        // Mostrar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar la contraseña: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
          "EDITAR PERFIL",
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
        child: _isLoading && !_isDataLoaded
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4D80E6),
                ),
              )
            : SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom > 0 
                        ? 20 
                        : MediaQuery.of(context).padding.bottom + 20,
                    left: 24.0,
                    right: 24.0,
                  ),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileHeader(),
                          const SizedBox(height: 24),
                          
                          // Campo Nombre
                          TextFormField(
                            controller: _nameController,
                            decoration: _buildInputDecoration('Nombre Completo', Icons.person),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu nombre';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Campo Email
                          TextFormField(
                            controller: _emailController,
                            decoration: _buildInputDecoration('Correo Electrónico', Icons.email),
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu correo';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Por favor ingresa un correo válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Campo Teléfono
                          TextFormField(
                            controller: _phoneController,
                            decoration: _buildInputDecoration('Teléfono', Icons.phone),
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.white),
                            // Sin validador porque podría ser opcional
                          ),
                          const SizedBox(height: 16),
                          
                          // Campo Fecha de Nacimiento
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: _buildInputDecoration('Fecha de Nacimiento', Icons.calendar_today),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _birthDate == null
                                        ? 'Seleccionar fecha'
                                        : DateFormat('dd/MM/yyyy').format(_birthDate!),
                                    style: TextStyle(
                                      color: _birthDate == null ? Colors.grey : Colors.white,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Color(0xFF4D80E6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Campo Género (Dropdown)
                          DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: _buildInputDecoration('Género', Icons.people),
                            dropdownColor: const Color(0xFF1E1E1E),
                            style: const TextStyle(color: Colors.white),
                            items: _genderOptions.map((String gender) {
                              return DropdownMenuItem<String>(
                                value: gender,
                                child: Text(gender),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _gender = newValue;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 32),
                          
                          // Botón de Guardar
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4D80E6),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 5,
                              shadowColor: const Color(0xFF4D80E6).withOpacity(0.5),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'GUARDAR PERFIL',
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
                          const SizedBox(height: 40),
                          
                          // Sección de cambio de contraseña (con expansión)
                          _buildPasswordSection(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
  
  // Widget para el encabezado del perfil
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          // Avatar o icono
          Container(
            width: 80,
            height: 80,
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
            child: const Center(
              child: Icon(
                Icons.person,
                size: 40,
                color: Color(0xFF4D80E6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            "PERFIL DE DEPORTISTA",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: const Color(0xFF4D80E6).withOpacity(0.8),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Edita tu información para sincronizar con el sistema de ranking",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget para la sección de cambio de contraseña
  Widget _buildPasswordSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9567E0).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text(
            "CAMBIAR CONTRASEÑA",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          leading: const Icon(
            Icons.lock,
            color: Color(0xFF9567E0),
          ),
          trailing: Icon(
            _showPasswordSection ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: const Color(0xFF9567E0),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _showPasswordSection = expanded;
            });
          },
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  children: [
                    // Campo de contraseña actual
                    TextFormField(
                      controller: _currentPasswordController,
                      decoration: _buildInputDecoration(
                        'Contraseña Actual',
                        Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF9567E0),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCurrentPassword = !_obscureCurrentPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureCurrentPassword,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu contraseña actual';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de nueva contraseña
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: _buildInputDecoration(
                        'Nueva Contraseña',
                        Icons.lock,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF9567E0),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureNewPassword,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa una nueva contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de confirmación de contraseña
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: _buildInputDecoration(
                        'Confirmar Contraseña',
                        Icons.lock_clock,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF9567E0),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor confirma tu nueva contraseña';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Botón para cambiar contraseña
                    ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9567E0),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 3,
                        shadowColor: const Color(0xFF9567E0).withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'ACTUALIZAR CONTRASEÑA',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
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
  
  // Función auxiliar para crear decoraciones de input consistentes
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF4D80E6)),
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
          color: const Color(0xFF4D80E6).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF4D80E6),
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
}