import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../extensions/localization_extension.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      if (success && mounted) {
        // Pop back to login screen, then pop login to go to home
        Navigator.of(context).pop(); // Close signup
        Navigator.of(context).pop(); // Close login
      } else if (mounted && authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: const Color(0xFFEB5757),
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
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE0E0E0)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    context.tr('create_account'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('signup_subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF828282),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    style: const TextStyle(color: Color(0xFFE0E0E0)),
                    decoration: InputDecoration(
                      labelText: context.tr('name'),
                      labelStyle: const TextStyle(color: Color(0xFF828282)),
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF828282)),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF9B51E0)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('name_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Color(0xFFE0E0E0)),
                    decoration: InputDecoration(
                      labelText: context.tr('email'),
                      labelStyle: const TextStyle(color: Color(0xFF828282)),
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF828282)),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF9B51E0)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('email_required');
                      }
                      if (!value.contains('@')) {
                        return context.tr('email_invalid');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Color(0xFFE0E0E0)),
                    decoration: InputDecoration(
                      labelText: context.tr('password'),
                      labelStyle: const TextStyle(color: Color(0xFF828282)),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF828282)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: const Color(0xFF828282),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF9B51E0)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('password_required');
                      }
                      if (value.length < 6) {
                        return context.tr('password_too_short');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(color: Color(0xFFE0E0E0)),
                    decoration: InputDecoration(
                      labelText: context.tr('confirm_password'),
                      labelStyle: const TextStyle(color: Color(0xFF828282)),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF828282)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: const Color(0xFF828282),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF9B51E0)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('confirm_password_required');
                      }
                      if (value != _passwordController.text) {
                        return context.tr('passwords_dont_match');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Sign Up Button
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9B51E0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                context.tr('sign_up'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
