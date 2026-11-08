import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';
import '../../core/auth/google_auth_service.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../l10n/app_localizations.dart';

String localized(BuildContext context, String en, String km) =>
    Localizations.localeOf(context).languageCode == 'km' ? km : en;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    Timer(const Duration(milliseconds: 1200), () async {
      if (!mounted) return;
      final state = ref.read(appControllerProvider);
      if (!state.onboardingComplete) {
        context.go('/onboarding');
      } else {
        final api = ref.read(apiClientProvider);
        if (api.token == null) {
          context.go('/welcome');
          return;
        }
        try {
          final result = await api.request('/auth/me');
          final role =
              (result['user'] as Map<String, dynamic>)['role'] == 'owner'
              ? AppRole.owner
              : AppRole.traveler;
          await ref.read(appControllerProvider.notifier).setRole(role);
          await ref.read(appControllerProvider.notifier).loadServerData();
          if (mounted) {
            context.go(
              role == AppRole.owner ? '/owner/dashboard' : '/traveler/explore',
            );
          }
        } catch (_) {
          await api.clearToken();
          if (mounted) context.go('/welcome');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.brown,
    body: FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KhmerStayLogo(light: true),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).tagline,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.sandstone),
            ),
            const SizedBox(height: 34),
            SizedBox(
              width: 112,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  5,
                  (index) => Transform.rotate(
                    angle: index.isEven ? -.2 : .2,
                    child: const Icon(
                      Icons.spa_outlined,
                      color: AppColors.champagne,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final pages = [
      (
        s.onboardingOneTitle,
        s.onboardingOneBody,
        'assets/images/siem_reap_homestay.png',
      ),
      (
        s.onboardingTwoTitle,
        s.onboardingTwoBody,
        'assets/images/kampot_riverside.png',
      ),
      (
        s.onboardingThreeTitle,
        s.onboardingThreeBody,
        'assets/images/kep_coastal.png',
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextButton(
                  onPressed: () => context.go('/setup'),
                  child: Text(s.skip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final item = pages[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(28),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(item.$3, fit: BoxFit.cover),
                                const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Color(0x661A120C),
                                      ],
                                    ),
                                  ),
                                ),
                                const Positioned(
                                  left: 20,
                                  bottom: 20,
                                  child: KhmerStayLogo(
                                    light: true,
                                    compact: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          item.$1,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.$2,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: List.generate(
                        pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: index == _page ? 28 : 8,
                          height: 8,
                          margin: const EdgeInsetsDirectional.only(end: 6),
                          decoration: BoxDecoration(
                            color: index == _page
                                ? AppColors.gold
                                : AppColors.sandstone,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                  FilledButton(
                    key: const Key('onboarding-next'),
                    onPressed: () {
                      if (_page == pages.length - 1) {
                        context.go('/setup');
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Text(
                      _page == pages.length - 1 ? s.getStarted : s.next,
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

class PreferenceSetupScreen extends ConsumerWidget {
  const PreferenceSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const KhmerStayLogo(compact: true)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.preferences,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localized(
                        context,
                        'You can change these anytime from your account.',
                        'អ្នកអាចផ្លាស់ប្ដូរជម្រើសទាំងនេះនៅពេលណាក៏បានពីគណនី។',
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      s.language,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(s.khmer),
                          selected: state.locale.languageCode == 'km',
                          onSelected: (_) => ref
                              .read(appControllerProvider.notifier)
                              .setLocale(const Locale('km')),
                        ),
                        ChoiceChip(
                          label: Text(s.english),
                          selected: state.locale.languageCode == 'en',
                          onSelected: (_) => ref
                              .read(appControllerProvider.notifier)
                              .setLocale(const Locale('en')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      s.currency,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('KHR · ៛'),
                          selected: state.currency == CurrencyChoice.khr,
                          onSelected: (_) => ref
                              .read(appControllerProvider.notifier)
                              .setCurrency(CurrencyChoice.khr),
                        ),
                        ChoiceChip(
                          label: const Text('USD · \$'),
                          selected: state.currency == CurrencyChoice.usd,
                          onSelected: (_) => ref
                              .read(appControllerProvider.notifier)
                              .setCurrency(CurrencyChoice.usd),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('preferences-continue'),
                        onPressed: () async {
                          await ref
                              .read(appControllerProvider.notifier)
                              .completeOnboarding();
                          if (context.mounted) context.go('/role');
                        },
                        child: Text(s.continueLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: const KhmerStayLogo(compact: true)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusBadge(label: 'DEMO', color: AppColors.gold),
              ),
              const SizedBox(height: 18),
              Text(
                s.chooseRole,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 28),
              _RoleCard(
                icon: Icons.explore_outlined,
                title: s.traveler,
                body: localized(
                  context,
                  'Find and book unforgettable local stays.',
                  'ស្វែងរក និងកក់កន្លែងស្នាក់នៅក្នុងស្រុកដែលមិនអាចបំភ្លេចបាន។',
                ),
                action: s.continueTraveler,
                onTap: () async {
                  await ref
                      .read(appControllerProvider.notifier)
                      .setRole(AppRole.traveler);
                  if (context.mounted) context.go('/welcome');
                },
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.home_work_outlined,
                title: s.propertyOwner,
                body: localized(
                  context,
                  'Manage properties, bookings, and earnings.',
                  'គ្រប់គ្រងទីតាំង ការកក់ និងចំណូលរបស់អ្នក។',
                ),
                action: s.continueOwner,
                onTap: () async {
                  await ref
                      .read(appControllerProvider.notifier)
                      .setRole(AppRole.owner);
                  if (context.mounted) context.go('/welcome');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.champagne.withValues(alpha: .22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.gold),
          ),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(body),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(onPressed: onTap, child: Text(action)),
          ),
        ],
      ),
    ),
  );
}

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _googleLoading = false;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final role = ref.watch(appControllerProvider.select((state) => state.role));
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            role == AppRole.owner
                ? 'assets/images/kampot_riverside.png'
                : 'assets/images/siem_reap_homestay.png',
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x331A120C), Color(0xE62B2118)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const KhmerStayLogo(light: true),
                  const Spacer(),
                  Text(
                    role == AppRole.owner
                        ? localized(
                            context,
                            'Welcome, local host',
                            'សូមស្វាគមន៍ ម្ចាស់ទីតាំង',
                          )
                        : localized(
                            context,
                            'Cambodia feels closer from here',
                            'កម្ពុជាកាន់តែជិតស្និទ្ធពីទីនេះ',
                          ),
                    style: Theme.of(
                      context,
                    ).textTheme.displaySmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  if (role == AppRole.traveler) ...[
                    FilledButton.icon(
                      onPressed: () => context.push('/create-account'),
                      icon: const Icon(Icons.mail_outline_rounded),
                      label: Text(
                        localized(
                          context,
                          'Continue with email',
                          'បន្តជាមួយអ៊ីមែល',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                      onPressed: _googleLoading ? null : _continueWithGoogle,
                      icon: _googleLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.g_mobiledata_rounded, size: 28),
                      label: Text(
                        localized(
                          context,
                          'Continue with Google',
                          'បន្តជាមួយ Google',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/signin'),
                      child: Text(
                        localized(
                          context,
                          'Already have an account? Sign in',
                          'មានគណនីរួចហើយ? ចូលគណនី',
                        ),
                        style: const TextStyle(color: AppColors.champagne),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(appControllerProvider.notifier)
                              .loadServerData();
                          if (context.mounted) context.go('/traveler/explore');
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        }
                      },
                      child: Text(
                        localized(
                          context,
                          'Explore stays as a guest',
                          'មើលកន្លែងស្នាក់ជាភ្ញៀវ',
                        ),
                        style: const TextStyle(color: AppColors.champagne),
                      ),
                    ),
                  ] else ...[
                    FilledButton(
                      onPressed: () => context.push('/signin'),
                      child: Text(s.signIn),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                      onPressed: () => context.push('/create-account'),
                      child: Text(s.createAccount),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Center(
                    child: Text(
                      s.demoMode,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final result = await GoogleAuthService.instance.authenticate(
        ref.read(apiClientProvider),
      );
      final user = result['user'] as Map<String, dynamic>;
      final role = user['role'] == 'owner' ? AppRole.owner : AppRole.traveler;
      await ref.read(appControllerProvider.notifier).setRole(role);
      await ref.read(appControllerProvider.notifier).loadServerData();
      if (mounted) {
        context.go(
          role == AppRole.owner ? '/owner/dashboard' : '/traveler/explore',
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }
}

enum AuthKind { signIn, phone, otp, create, forgot }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.kind});
  final AuthKind kind;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _resetCodeSent = false;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _password.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final title = switch (widget.kind) {
      AuthKind.signIn => s.welcomeBack,
      AuthKind.phone => s.signInPhone,
      AuthKind.otp => s.otpTitle,
      AuthKind.create => s.createAccount,
      AuthKind.forgot => s.forgotPassword,
    };
    final needsEmail = {
      AuthKind.signIn,
      AuthKind.create,
      AuthKind.forgot,
    }.contains(widget.kind);
    final needsPassword = {
      AuthKind.signIn,
      AuthKind.create,
    }.contains(widget.kind);
    final pendingEmail = ref
        .read(preferencesProvider)
        ?.getString('pendingOtpEmail');
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const KhmerStayLogo(),
                    const SizedBox(height: 32),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    if (widget.kind == AuthKind.otp) ...[
                      Text(s.otpHint),
                      if (pendingEmail != null && pendingEmail.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          pendingEmail,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    if (widget.kind == AuthKind.create) ...[
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: s.fullName,
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? s.requiredField
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (needsEmail)
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: s.email,
                          prefixIcon: const Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return s.requiredField;
                          }
                          if (!value.contains('@')) return s.validEmail;
                          return null;
                        },
                      ),
                    if (widget.kind == AuthKind.phone)
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: s.email,
                          prefixIcon: const Icon(Icons.mail_outlined),
                        ),
                        validator: (value) =>
                            value == null || !value.contains('@')
                            ? s.requiredField
                            : null,
                      ),
                    if (widget.kind == AuthKind.otp)
                      TextFormField(
                        key: const Key('otp-field'),
                        controller: _otp,
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: s.verify,
                          prefixIcon: const Icon(Icons.password_rounded),
                        ),
                        validator: (value) =>
                            value == null || !RegExp(r'^\d{6}$').hasMatch(value)
                            ? s.sixDigits
                            : null,
                      ),
                    if (widget.kind == AuthKind.forgot && _resetCodeSent) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(labelText: s.verify),
                      ),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: InputDecoration(labelText: s.password),
                      ),
                    ],
                    if (needsPassword) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: s.password,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.length < 8
                            ? s.requiredField
                            : null,
                      ),
                    ],
                    if (widget.kind == AuthKind.signIn)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: () => context.push('/forgot'),
                          child: Text(s.forgotPassword),
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.kind == AuthKind.otp
                                  ? s.verify
                                  : widget.kind == AuthKind.create
                                  ? localized(
                                      context,
                                      'Continue with email',
                                      'បន្តជាមួយអ៊ីមែល',
                                    )
                                  : s.continueLabel,
                            ),
                    ),
                    if (widget.kind == AuthKind.otp)
                      TextButton(
                        onPressed: _loading ? null : _resendCode,
                        child: Text(
                          localized(
                            context,
                            'Send a new code',
                            'ផ្ញើលេខកូដថ្មី',
                          ),
                        ),
                      ),
                    if ({
                      AuthKind.signIn,
                      AuthKind.create,
                    }.contains(widget.kind)) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(localized(context, 'or', 'ឬ')),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _googleAuth,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                        label: Text(
                          localized(
                            context,
                            'Continue with Google',
                            'បន្តជាមួយ Google',
                          ),
                        ),
                      ),
                    ],
                    if (widget.kind == AuthKind.signIn) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/phone'),
                        icon: const Icon(Icons.mail_outlined),
                        label: Text(
                          localized(
                            context,
                            'Sign in with email code',
                            'ចូលដោយលេខកូដអ៊ីមែល',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      localized(
                        context,
                        'By continuing, you agree to the KhmerStay Terms and Privacy Policy.',
                        'ដោយបន្ត អ្នកយល់ព្រមតាមលក្ខខណ្ឌ និងគោលការណ៍ឯកជនភាពរបស់ KhmerStay។',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final api = ref.read(apiClientProvider);
    final prefs = ref.read(preferencesProvider);
    try {
      switch (widget.kind) {
        case AuthKind.signIn:
          final result = await api.login(_email.text.trim(), _password.text);
          await _finishAuth(result);
        case AuthKind.phone:
          await api.request(
            '/auth/otp/request',
            method: 'POST',
            body: {'email': _phone.text.trim(), 'purpose': 'login'},
          );
          await prefs?.setString('pendingOtpEmail', _phone.text.trim());
          await prefs?.setString('pendingOtpPurpose', 'login');
          if (mounted) context.push('/otp');
        case AuthKind.otp:
          final email = prefs?.getString('pendingOtpEmail') ?? '';
          final purpose = prefs?.getString('pendingOtpPurpose') ?? 'login';
          final result = await api.verifyOtp(email, _otp.text.trim(), purpose);
          await prefs?.remove('pendingOtpEmail');
          await prefs?.remove('pendingOtpPurpose');
          await _finishAuth(result);
        case AuthKind.create:
          await api.request(
            '/auth/register',
            method: 'POST',
            body: {
              'name': _name.text.trim(),
              'email': _email.text.trim(),
              'password': _password.text,
              'role': ref.read(appControllerProvider).role.name,
            },
          );
          await prefs?.setString('pendingOtpEmail', _email.text.trim());
          await prefs?.setString('pendingOtpPurpose', 'verify_email');
          if (mounted) context.push('/otp');
        case AuthKind.forgot:
          if (!_resetCodeSent) {
            await api.request(
              '/auth/otp/request',
              method: 'POST',
              body: {'email': _email.text.trim(), 'purpose': 'reset'},
            );
            if (mounted) setState(() => _resetCodeSent = true);
          } else {
            await api.request(
              '/auth/password/reset',
              method: 'POST',
              body: {
                'email': _email.text.trim(),
                'code': _otp.text.trim(),
                'password': _password.text,
              },
            );
            if (mounted) context.go('/signin');
          }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendCode() async {
    final prefs = ref.read(preferencesProvider);
    final email = prefs?.getString('pendingOtpEmail') ?? '';
    final purpose = prefs?.getString('pendingOtpPurpose') ?? 'login';
    if (email.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(apiClientProvider)
          .request(
            '/auth/otp/request',
            method: 'POST',
            body: {'email': email, 'purpose': purpose},
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localized(
                context,
                'A new code has been requested.',
                'បានស្នើលេខកូដថ្មី។',
              ),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleAuth() async {
    setState(() => _loading = true);
    try {
      final result = await GoogleAuthService.instance.authenticate(
        ref.read(apiClientProvider),
      );
      await _finishAuth(result);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finishAuth(Map<String, dynamic> result) async {
    final user = result['user'] as Map<String, dynamic>;
    final role = user['role'] == 'owner' ? AppRole.owner : AppRole.traveler;
    await ref.read(appControllerProvider.notifier).setRole(role);
    await ref.read(appControllerProvider.notifier).loadServerData();
    if (mounted) {
      context.go(
        role == AppRole.owner ? '/owner/dashboard' : '/traveler/explore',
      );
    }
  }
}
