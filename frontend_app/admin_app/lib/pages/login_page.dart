import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../config/app_style.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await _authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        if (mounted) {
          final isLoggedIn = await _authService.isLoggedIn();
          if (isLoggedIn) {
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
          } else {
            throw Exception('Erreur de connexion. Veuillez réessayer.');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().replaceAll('Exception: ', ''),
                style: const TextStyle(color: Colors.white),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppStyle.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyle.radiusMedium),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: AppStyle.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppStyle.primaryColor.withOpacity(0.95),
              AppStyle.secondaryColor.withOpacity(0.95),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 32,
              vertical: 32,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? double.infinity : 500,
              ),
              child: Card(
                elevation: AppStyle.elevationMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyle.radiusLarge),
                ),
                child: Container(
                  padding: const EdgeInsets.all(40.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppStyle.radiusLarge),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        AppStyle.backgroundColor.withOpacity(0.5),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppStyle.primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppStyle.buildLogo(height: 80),
                        const SizedBox(height: 24),
                        Text(
                          'Administration',
                          style: AppStyle.headingStyle.copyWith(
                            color: AppStyle.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Artisanat éco-responsable',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppStyle.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontSize: 16,
                            letterSpacing: 0.3,
                          ),
                          decoration: AppStyle.textFieldDecoration(
                            label: 'Email',
                            icon: Icons.email_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre email';
                            }
                            if (!value.contains('@')) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 16,
                            letterSpacing: 0.3,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            labelStyle: TextStyle(
                              color: AppStyle.textSecondaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: AppStyle.primaryColor,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppStyle.primaryColor,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppStyle.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppStyle.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppStyle.radiusMedium),
                              borderSide: const BorderSide(
                                color: AppStyle.primaryColor,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: AppStyle.backgroundColor,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Implémenter la récupération de mot de passe
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppStyle.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
                              ),
                            ),
                            child: const Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleLogin,
                            icon: _isLoading 
                                ? const SizedBox.shrink()
                                : const Icon(Icons.login_rounded),
                            label: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Se connecter',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                            style: AppStyle.primaryButtonStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 