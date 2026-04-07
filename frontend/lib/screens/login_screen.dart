import 'package:flutter/material.dart';

import '../models/app_user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
  });

  final ValueChanged<AppUser> onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorText;

  static const _accounts = <String, ({String password, UserRole role})>{
    'admin': (password: 'admin123', role: UserRole.admin),
    'operator': (password: 'user123', role: UserRole.operator),
  };

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final account = _accounts[username];

    if (account == null || account.password != password) {
      setState(() => _errorText = 'Wrong username or password.');
      return;
    }

    setState(() => _errorText = null);
    widget.onLogin(AppUser(username: username, role: account.role));
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
            final compact = constraints.maxWidth < 900;
            final intro = _buildIntro(theme, compact);
            final formCard = _buildForm(theme);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            intro,
                            const SizedBox(height: 24),
                            formCard,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: intro),
                            const SizedBox(width: 24),
                            Expanded(child: formCard),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIntro(ThemeData theme, bool compact) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
        const SizedBox(height: 20),
        Text(
          'Log in to unlock the admin cockpit.',
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: 18),
        Text(
          'Admins get the full CRUD workspace for games, credentials, FAQs, and discussions. '
          'Operators get a cleaner read-only view.',
          style: theme.textTheme.titleMedium?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: const [
            _InfoChip(
              icon: Icons.shield_outlined,
              title: 'Admin',
              subtitle: 'Username: admin  Password: admin123',
            ),
            _InfoChip(
              icon: Icons.person_outline,
              title: 'Operator',
              subtitle: 'Username: operator  Password: user123',
            ),
          ],
        ),
        if (!compact) const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Use the demo login to enter the panel.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a username';
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
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.login),
                  label: const Text('Enter Panel'),
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
      width: 260,
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
