import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_bar.dart';
import '../services/admin_repository.dart';

/// Sub-city metadata categorized into Central and Outer sub-cities
class DispatchSubCity {
  final String name;
  final String category; // 'Central Sub-cities' or 'Outer Sub-cities'
  final String description;

  const DispatchSubCity({
    required this.name,
    required this.category,
    required this.description,
  });
}

const List<DispatchSubCity> kAddisSubCities = [
  // Central Sub-cities
  DispatchSubCity(
    name: 'Addis Ketema',
    category: 'Central Sub-cities',
    description: 'Located in the northwestern center of the city and home to Addis Mercato.',
  ),
  DispatchSubCity(
    name: 'Arada',
    category: 'Central Sub-cities',
    description: 'Situated in the historic north-central core, encompassing landmarks like Piassa and 4 Kilo.',
  ),
  DispatchSubCity(
    name: 'Kirkos',
    category: 'Central Sub-cities',
    description: 'Positioned in the central business and diplomatic district, hosting major international organizations.',
  ),
  DispatchSubCity(
    name: 'Lideta',
    category: 'Central Sub-cities',
    description: 'Located in the west-central part of the capital between Kirkos and Kolfe Keranio.',
  ),
  // Outer Sub-cities
  DispatchSubCity(
    name: 'Akaki Kality',
    category: 'Outer Sub-cities',
    description: 'Located at the southern tip of Addis Ababa and serves as a primary industrial zone.',
  ),
  DispatchSubCity(
    name: 'Bole',
    category: 'Outer Sub-cities',
    description: 'Situated in the southeast and known for Bole International Airport and major commercial hubs.',
  ),
  DispatchSubCity(
    name: 'Gulele',
    category: 'Outer Sub-cities',
    description: 'Located in the northern part of the city, bordering the Entoto mountains.',
  ),
  DispatchSubCity(
    name: 'Kolfe Keranio',
    category: 'Outer Sub-cities',
    description: 'Positioned along the western edge of the capital.',
  ),
  DispatchSubCity(
    name: 'Lemi Kura',
    category: 'Outer Sub-cities',
    description: 'Established in 2020 as the 11th sub-city on the eastern side of Addis Ababa from areas previously under Bole and Yeka.',
  ),
  DispatchSubCity(
    name: 'Nifas Silk-Lafto',
    category: 'Outer Sub-cities',
    description: 'Located in the southwest of the city.',
  ),
  DispatchSubCity(
    name: 'Yeka',
    category: 'Outer Sub-cities',
    description: 'Located in the northeast / eastern area bordering Yeka hills.',
  ),
];

/// Screen 2 — Dispatcher Registration.
///
/// Phase 1 Provisioning & RBAC:
/// Dispatcher accounts are audited and PROVISIONED, not self-granted.
/// 1. System auto-assigns guaranteed unique Employee IDs and validated callsigns.
/// 2. Dispatch center selection is divided between Central and Outer sub-cities.
/// 3. Prevents duplicate registrations from existing dispatchers upfront.
/// 4. Provides password entry with strong password generation.
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _radioCallsignController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _subCityCategory = 'Central Sub-cities';
  late DispatchSubCity _selectedSubCity;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _suggestedPasswordNotice;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedSubCity = kAddisSubCities[1]; // Arada default
    _employeeIdController.text = AdminRepository.instance.generateUniqueEmployeeId();
    _radioCallsignController.text = AdminRepository.instance.generateUniqueRadioCallsign();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeIdController.dispose();
    _radioCallsignController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _generateStrongPassword() {
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghijkmnopqrstuvwxyz';
    const numbers = '23456789';
    const special = '@#\$%!&*?';
    final rand = math.Random.secure();
    final chars = <String>[];
    for (int i = 0; i < 3; i++) {
      chars.add(upper[rand.nextInt(upper.length)]);
    }
    for (int i = 0; i < 4; i++) {
      chars.add(lower[rand.nextInt(lower.length)]);
    }
    for (int i = 0; i < 3; i++) {
      chars.add(numbers[rand.nextInt(numbers.length)]);
    }
    for (int i = 0; i < 2; i++) {
      chars.add(special[rand.nextInt(special.length)]);
    }
    chars.shuffle(rand);
    return chars.join();
  }

  void _suggestStrongPassword() {
    final pwd = _generateStrongPassword();
    setState(() {
      _passwordController.text = pwd;
      _confirmPasswordController.text = pwd;
      _obscurePassword = false;
      _obscureConfirm = false;
      _suggestedPasswordNotice = pwd;
    });
    Clipboard.setData(ClipboardData(text: pwd));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Strong password suggested and copied to clipboard: $pwd'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _regenerateEmployeeId() {
    final newId = AdminRepository.instance.generateUniqueEmployeeId();
    setState(() {
      _employeeIdController.text = newId;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('System assigned unique Employee ID: $newId'),
        backgroundColor: AppColors.chipBg,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _regenerateCallsign() {
    final newCall = AdminRepository.instance.generateUniqueRadioCallsign();
    setState(() {
      _radioCallsignController.text = newCall;
    });
  }

  void _setSubCityCategory(String cat) {
    setState(() {
      _subCityCategory = cat;
      final match = kAddisSubCities.firstWhere(
        (s) => s.category == cat,
        orElse: () => kAddisSubCities.first,
      );
      _selectedSubCity = match;
    });
  }

  void _setSubCity(DispatchSubCity s) {
    setState(() {
      _selectedSubCity = s;
      _subCityCategory = s.category;
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text('Please correct the validation errors in the form before submitting.'),
              ),
            ],
          ),
          backgroundColor: AppColors.brandRed,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match. Please verify both fields.'),
          backgroundColor: AppColors.brandRed,
        ),
      );
      return;
    }

    // Duplicate check: MUST NOT let it submit for review in the first place!
    final conflict = AdminRepository.instance.findDispatcherConflict(
      email: _emailController.text,
      fullName: _fullNameController.text,
      employeeId: _employeeIdController.text,
      radioCallsign: _radioCallsignController.text,
    );
    if (conflict != null) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.block_rounded, color: AppColors.brandRed, size: 40),
          title: const Text('Application Blocked'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conflict,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                'The system prevents duplicate registrations. If this is your account, please sign in. If you need assistance, contact your dispatch administrator.',
                style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Edit Application'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/login');
              },
              child: const Text('Go to Portal Sign In'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final dispatchCenterText = '${_selectedSubCity.name} Command Center (${_selectedSubCity.category})';
      await AdminRepository.instance.submitRegistration(
        fullName: _fullNameController.text,
        employeeId: _employeeIdController.text,
        dispatchCenter: dispatchCenterText,
        radioCallsign: _radioCallsignController.text,
        email: _emailController.text,
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _submitting = false);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.mark_email_read_outlined,
              color: AppColors.brandRed, size: 36),
          title: const Text('Application Submitted for Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registration request for ${_fullNameController.text.trim()} '
                'has been recorded with Employee ID ${_employeeIdController.text} '
                'at ${_selectedSubCity.name} (${_selectedSubCity.category}).',
                style: const TextStyle(fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.chipBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assigned Station: ${_selectedSubCity.name} (${_selectedSubCity.category})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Callsign: ${_radioCallsignController.text}',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Password: Set and secured for account activation',
                        style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Once an administrator approves your application in the Admin Console, you will be able to log in directly with your email and chosen password.',
                style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Return to Portal Sign In'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notice: $msg'),
          backgroundColor: AppColors.brandRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeModeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
          extendBodyBehindAppBar: true,
          appBar: BrandBar(
            tagline: 'Addis Ababa Command Portal',
            showBackButton: true,
            backRoute: '/',
            actions: [
              HeaderHoverButton(
                label: 'Portal Sign In',
                isPrimary: true,
                icon: Icons.login_rounded,
                onPressed: () => context.go('/login'),
              ),
            ],
            navItems: [
              BrandBarAction(
                label: 'Portal Sign In',
                isPrimary: true,
                icon: Icons.login_rounded,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: MaxWidthCenter(
              maxWidth: 1040,
              child: Padding(
                padding: const EdgeInsets.only(top: 72, bottom: 32, left: 32, right: 32),
                child: LayoutBuilder(builder: (context, c) {
                  final stacked = c.maxWidth < 820;
                  const left = _PortalInfoPanel();
                  final right = _RegistrationForm(
                    formKey: _formKey,
                    fullNameController: _fullNameController,
                    employeeIdController: _employeeIdController,
                    onRegenerateEmployeeId: _regenerateEmployeeId,
                    selectedSubCityCategory: _subCityCategory,
                    selectedSubCity: _selectedSubCity,
                    onCategoryChanged: _setSubCityCategory,
                    onSubCityChanged: _setSubCity,
                    radioCallsignController: _radioCallsignController,
                    onGenerateCallsign: _regenerateCallsign,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    obscurePassword: _obscurePassword,
                    obscureConfirm: _obscureConfirm,
                    onToggleObscurePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onToggleObscureConfirm: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    onSuggestStrongPassword: _suggestStrongPassword,
                    suggestedPasswordNotice: _suggestedPasswordNotice,
                    submitting: _submitting,
                    onSubmit: _submit,
                  );
                  if (stacked) {
                    return Column(children: [left, const SizedBox(height: 24), right]);
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(flex: 4, child: left),
                      const SizedBox(width: 24),
                      Expanded(flex: 5, child: right),
                    ],
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PortalInfoPanel extends StatelessWidget {
  const _PortalInfoPanel();

  @override
  Widget build(BuildContext context) {
    final features = const [
      ('Real-Time Vehicle Tracking', Icons.gps_fixed),
      ('Intelligent Triage Engine', Icons.bolt),
      ('Unified Hospital Feeds', Icons.local_hospital_outlined),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dispatcher Portal',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 8),
        Text(
          'Authorized personnel only. This command center portal '
          'coordinates live telemetry, resource allocation, and dispatch '
          'across the Addis Ababa emergency response network.',
          style: TextStyle(color: AppColors.inkSoft, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        Text('System features',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft)),
        const SizedBox(height: 12),
        for (final f in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(f.$2, size: 18, color: AppColors.brandRed),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    f.$1,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.brandRed.withValues(alpha: 0.06),
            border: Border.all(color: AppColors.brandRed.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_user, color: AppColors.brandRed, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dispatcher provisioning is audited. Every request is '
                  'reviewed and logged against hospital and road-safety '
                  'regulations before activation.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.ink, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegistrationForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController employeeIdController;
  final VoidCallback onRegenerateEmployeeId;
  final String selectedSubCityCategory;
  final DispatchSubCity selectedSubCity;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<DispatchSubCity> onSubCityChanged;
  final TextEditingController radioCallsignController;
  final VoidCallback onGenerateCallsign;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onToggleObscureConfirm;
  final VoidCallback onSuggestStrongPassword;
  final String? suggestedPasswordNotice;
  final bool submitting;
  final VoidCallback onSubmit;

  const _RegistrationForm({
    required this.formKey,
    required this.fullNameController,
    required this.employeeIdController,
    required this.onRegenerateEmployeeId,
    required this.selectedSubCityCategory,
    required this.selectedSubCity,
    required this.onCategoryChanged,
    required this.onSubCityChanged,
    required this.radioCallsignController,
    required this.onGenerateCallsign,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onToggleObscurePassword,
    required this.onToggleObscureConfirm,
    required this.onSuggestStrongPassword,
    required this.suggestedPasswordNotice,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Request Dispatcher Access',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(
                'Enter your personnel credentials. The system automatically assigns a unique Employee ID and validates your credentials.',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
              ),
              const SizedBox(height: 20),
              _FieldRow(children: [
                _LabeledField(
                  label: 'Full Name',
                  hint: 'e.g. Dawit Alemu',
                  controller: fullNameController,
                  validator: _required,
                ),
                _LabeledField(
                  label: 'Employee ID (System Assigned)',
                  hint: 'DSP-2026-XXXX',
                  controller: employeeIdController,
                  readOnly: true,
                  helperText: 'Guaranteed unique ID assigned by system.',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: 'Generate new unique ID',
                    onPressed: onRegenerateEmployeeId,
                  ),
                  validator: _required,
                ),
              ]),

              // Dispatch Center: Divided by Sub-city (Central vs Outer)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_city_rounded, size: 16, color: AppColors.brandRed),
                        const SizedBox(width: 8),
                        Text(
                          'Dispatch Center (Choose Sub-city)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Central vs Outer Selector
                    Row(
                      children: [
                        Expanded(
                          child: _SubCityCategoryChip(
                            label: 'Central Sub-cities (4)',
                            selected: selectedSubCityCategory == 'Central Sub-cities',
                            onTap: () => onCategoryChanged('Central Sub-cities'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SubCityCategoryChip(
                            label: 'Outer Sub-cities (7)',
                            selected: selectedSubCityCategory == 'Outer Sub-cities',
                            onTap: () => onCategoryChanged('Outer Sub-cities'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DispatchSubCity>(
                      value: selectedSubCity,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Sub-city Command Center',
                        isDense: true,
                      ),
                      items: kAddisSubCities
                          .where((s) => s.category == selectedSubCityCategory)
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  '${s.name} (${s.category})',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) onSubCityChanged(v);
                      },
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.chipBg,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 15, color: AppColors.inkSoft),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${selectedSubCity.name}: ${selectedSubCity.description}',
                              style: TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              _FieldRow(children: [
                _LabeledField(
                  label: 'Radio Callsign (Unique Combination)',
                  hint: 'e.g. ALPHA-12',
                  controller: radioCallsignController,
                  helperText: 'Guaranteed unique radio combination across network.',
                  suffixIcon: TextButton.icon(
                    onPressed: onGenerateCallsign,
                    icon: const Icon(Icons.auto_awesome, size: 14),
                    label: const Text('Generate', style: TextStyle(fontSize: 11)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Radio callsign required';
                    if (AdminRepository.instance.isRadioCallsignTaken(v.trim())) {
                      return 'This callsign combination is already taken';
                    }
                    return null;
                  },
                ),
                _LabeledField(
                  label: 'Official Work Email',
                  hint: 'e.g. name@addisababa.gov.et',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _email,
                ),
              ]),

              // Password Option & Strong Password Suggestion
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.brandRed),
                        const SizedBox(width: 8),
                        Text(
                          'Dispatcher Access Password',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: onSuggestStrongPassword,
                          icon: const Icon(Icons.vpn_key_rounded, size: 14),
                          label: const Text('Suggest Strong Password',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            foregroundColor: AppColors.brandRed,
                            side: const BorderSide(color: AppColors.brandRed),
                          ),
                        ),
                      ],
                    ),
                    if (suggestedPasswordNotice != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF059669)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Suggested Strong Password: $suggestedPasswordNotice (Copied to Clipboard)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Create Password',
                              hintText: 'Minimum 6 characters',
                              isDense: true,
                              suffixIcon: IconButton(
                                icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                                onPressed: onToggleObscurePassword,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Password required';
                              if (v.trim().length < 6) return 'Minimum 6 characters';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: confirmPasswordController,
                            obscureText: obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Re-enter password',
                              isDense: true,
                              suffixIcon: IconButton(
                                icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18),
                                onPressed: onToggleObscureConfirm,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Confirm password required';
                              if (v.trim() != passwordController.text.trim()) return 'Passwords do not match';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting ? null : onSubmit,
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Application for Review'),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Already have an approved account?',
                        style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Portal Sign In'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  static String? _email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
    return null;
  }
}

class _SubCityCategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SubCityCategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandRed : AppColors.chipBg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.brandRed : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays two fields side-by-side on wide screens, stacks on narrow ones.
class _FieldRow extends StatelessWidget {
  final List<Widget> children;
  const _FieldRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 460) {
        return Column(children: children);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i != children.length - 1) const SizedBox(width: 16),
          ],
        ],
      );
    });
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscure;
  final bool readOnly;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final String? helperText;

  const _LabeledField({
    required this.label,
    required this.hint,
    this.obscure = false,
    this.readOnly = false,
    this.controller,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            readOnly: readOnly,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: suffixIcon,
              helperText: helperText,
              helperStyle: TextStyle(fontSize: 11, color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}
