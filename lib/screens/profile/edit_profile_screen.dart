import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/ui_utils.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  bool _wantsPasswordChange = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  final _newPassFocus = FocusNode();

  bool get _hasMinLength => _newPassCtrl.text.length >= 8;
  bool get _hasUppercase => _newPassCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _newPassCtrl.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _newPassCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _newPassCtrl.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get _isPasswordValid => _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber && _hasSpecial;

  bool get _isFormReady {
    if (_nameCtrl.text.trim().isEmpty) return false;
    if (_emailCtrl.text.trim().isEmpty) return false;

    final user = context.read<AuthProvider>().currentUser;
    final nameChanged = _nameCtrl.text.trim() != user?.name;
    final emailChanged = _emailCtrl.text.trim() != user?.email;

    if (_wantsPasswordChange) {
      if (_currentPassCtrl.text.isEmpty) return false;
      if (!_isPasswordValid) return false;
      if (_currentPassCtrl.text == _newPassCtrl.text) return false;
      return true;
    } else {
      return nameChanged || emailChanged;
    }
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _newPassFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _newPassFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'El correo es requerido.';
    final emailExp = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (!emailExp.hasMatch(value.trim())) {
      return 'Ingresa un formato de correo válido.';
    }
    return null;
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? Colors.green : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12.5,
              decoration: isMet ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;

    final nameChanged = _nameCtrl.text.trim() != user.name;
    final emailChanged = _emailCtrl.text.trim() != user.email;

    if (!nameChanged && !emailChanged && !_wantsPasswordChange) {
      Navigator.pop(context);
      return;
    }

    final ok = await auth.updateProfile(
      name: nameChanged ? _nameCtrl.text.trim() : null,
      email: emailChanged ? _emailCtrl.text.trim() : null,
      password: _wantsPasswordChange ? _newPassCtrl.text : null,
      currentPassword: _wantsPasswordChange ? _currentPassCtrl.text : null,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
      UiUtils.showSuccessModal(context, '¡Éxito!', 'Perfil actualizado con éxito');
    } else {
      UiUtils.showErrorModal(context, 'Error al guardar', auth.errorMessage ?? 'Contraseña actual incorrecta o hubo un problema de conexión.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Editar perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'El nombre es requerido.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 24),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cambiar contraseña'),
                value: _wantsPasswordChange,
                onChanged: (v) {
                  setState(() {
                    _wantsPasswordChange = v;
                    if (!v) {
                      _currentPassCtrl.clear();
                      _newPassCtrl.clear();
                    }
                  });
                },
              ),

              if (_wantsPasswordChange) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _currentPassCtrl,
                  obscureText: _obscureCurrent,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (v) => _wantsPasswordChange && (v == null || v.isEmpty)
                      ? 'Ingresa tu contraseña actual.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPassCtrl,
                  focusNode: _newPassFocus,
                  obscureText: _obscureNew,
                  onChanged: (_) => setState(() {}),
                  enabled: _currentPassCtrl.text.isNotEmpty,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (_newPassCtrl.text.isNotEmpty && !_isPasswordValid) {
                      return 'La nueva contraseña no cumple los requisitos.';
                    }
                    if (_newPassCtrl.text.isNotEmpty && _newPassCtrl.text == _currentPassCtrl.text) {
                      return 'No puede ser igual a la actual.';
                    }
                    return null;
                  },
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: (!_newPassFocus.hasFocus && _newPassCtrl.text.isEmpty)
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 8, left: 12),
                          child: (!_hasMinLength)
                              ? _buildRequirement('Al menos 8 caracteres', false)
                              : (!_hasUppercase)
                                  ? _buildRequirement('Una letra mayúscula (A-Z)', false)
                                  : (!_hasLowercase)
                                      ? _buildRequirement('Una letra minúscula (a-z)', false)
                                      : (!_hasNumber)
                                          ? _buildRequirement('Al menos un número (0-9)', false)
                                          : (!_hasSpecial)
                                              ? _buildRequirement('Un símbolo especial (@, #, !, etc.)', false)
                                              : const SizedBox.shrink(),
                        ),
                ),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: (_isFormReady && !auth.isLoading) ? _submit : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar cambios',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}