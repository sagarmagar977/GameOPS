import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/app_user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
    this.initialEmail,
  });

  final Future<void> Function(AppUser user, bool rememberMe) onLogin;
  final String? initialEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = const ApiClient();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isRegisterMode = false;
  bool _isSubmitting = false;
  bool _rememberMe = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initialEmail = widget.initialEmail?.trim() ?? '';
    if (initialEmail.isNotEmpty) {
      _emailController.text = initialEmail;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final payload = _isRegisterMode
          ? await _api.register(
              email,
              _passwordController.text,
              _confirmPasswordController.text,
            )
          : await _api.login(
              email,
              _passwordController.text,
            );

      if (!mounted) {
        return;
      }

      await widget.onLogin(AppUser.fromAuthResponse(payload), _rememberMe);
    } catch (error) {
      setState(() => _errorText = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF5F6), Color(0xFFF7FBFB), Color(0xFFE7F0F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 420 ? 16.0 : 24.0;
            final formCard = _buildForm(theme);

            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: formCard,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('GameOps Control Room'),
              ),
              const SizedBox(height: 18),
              Text(
                _isRegisterMode ? 'Create account' : 'Welcome back',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _isRegisterMode
                    ? 'Use your email and a password with at least 6 characters.'
                    : 'Use your backend email and password to enter the panel.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              if (!_isRegisterMode) ...[
                const _InfoChip(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin Login',
                  subtitle: 'Email: admin@example.com\nPassword: admin123',
                ),
                const SizedBox(height: 18),
              ],
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return 'Enter your email';
                  }
                  if (!email.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a password';
                  }
                  if (_isRegisterMode && value.length < 6) {
                    return 'Use at least 6 characters';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (!_isRegisterMode) {
                    _submit();
                  }
                },
              ),
              if (_isRegisterMode) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Re-enter password',
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword,
                        );
                      },
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (!_isRegisterMode) {
                      return null;
                    }
                    if (value == null || value.isEmpty) {
                      return 'Re-enter your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 14),
                Text(
                  _errorText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _rememberMe,
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() => _rememberMe = value ?? true);
                      },
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Remember me'),
                subtitle: const Text('Keep me signed in after browser refresh or app restart'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: Icon(_isRegisterMode ? Icons.person_add_alt_1 : Icons.login),
                  label: Text(
                    _isSubmitting
                        ? 'Please wait...'
                        : _isRegisterMode
                            ? 'Create Account'
                            : 'Enter Panel',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _isRegisterMode = !_isRegisterMode;
                            _errorText = null;
                          });
                        },
                  child: Text(
                    _isRegisterMode
                        ? 'Already have an account? Log in'
                        : 'Need an account? Create one',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
