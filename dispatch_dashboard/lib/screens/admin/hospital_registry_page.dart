import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/account_status_pill.dart';
import '../../widgets/admin_scaffold.dart';
import '../../services/admin_repository.dart';

/// Admin Panel screen 4 — Hospital & Ambulance Registry.
///
/// Real-time streaming from Firestore `hospitals` and `ambulances`.
/// Sensitive mutations (creation, bed updates, unit provisioning) are executed
/// via Cloud Functions callables with full audit logging.
class HospitalRegistryPage extends StatefulWidget {
  const HospitalRegistryPage({super.key});

  @override
  State<HospitalRegistryPage> createState() => _HospitalRegistryPageState();
}

class _HospitalRegistryPageState extends State<HospitalRegistryPage> {
  Future<void> _showAddStaffDialog(HospitalRecord hospital) async {
    final nameCtl = TextEditingController();
    final emailCtl = TextEditingController();
    final empIdCtl = TextEditingController();
    AccountRole selectedRole = AccountRole.hospitalStaff;
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Assign Staff to ${hospital.name}'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register authorized medical personnel, dispatch operators, or ambulance crew stationed at this facility.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtl,
                      decoration: const InputDecoration(
                        labelText: 'Staff Full Name',
                        hintText: 'e.g. Dr. Helen Bekele',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtl,
                      decoration: const InputDecoration(
                        labelText: 'Work Email / Login ID',
                        hintText: 'e.g. helen.b@hiwonet.et',
                      ),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Valid email required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AccountRole>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Facility Role'),
                      items: const [
                        DropdownMenuItem(
                          value: AccountRole.hospitalStaff,
                          child: Text('Hospital Staff (ER Triage / Ward Nurse)'),
                        ),
                        DropdownMenuItem(
                          value: AccountRole.crew,
                          child: Text('Ambulance Crew (EMT / Paramedic)'),
                        ),
                        DropdownMenuItem(
                          value: AccountRole.dispatcher,
                          child: Text('Hospital Dispatcher (Station Operator)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: empIdCtl,
                      decoration: const InputDecoration(
                        labelText: 'Employee ID / Radio Callsign (Optional)',
                        hintText: 'e.g. MED-702',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        try {
                          await AdminRepository.instance.registerHospitalStaff(
                            hospitalName: hospital.name,
                            fullName: nameCtl.text.trim(),
                            email: emailCtl.text.trim(),
                            role: selectedRole,
                            employeeId: empIdCtl.text.trim(),
                          );
                          if (!context.mounted) return;
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${nameCtl.text.trim()} registered as ${selectedRole.label} at ${hospital.name}.',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          setDialogState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to register staff: $e'),
                              backgroundColor: AppColors.brandRed,
                            ),
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Register Staff Account'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showRegisterHospitalDialog(List<HospitalRecord> hospitals) async {
    final nameCtl = TextEditingController();
    final bedsCtl = TextEditingController(text: '30');
    final icuCtl = TextEditingController(text: '6');
    final ambCtl = TextEditingController(text: '2');
    final addressCtl = TextEditingController(text: 'Bole Sub-city');
    final specCtl = TextEditingController(text: 'General & Emergency Care');
    bool addStaff = false;
    final staffNameCtl = TextEditingController();
    final staffEmailCtl = TextEditingController();
    AccountRole staffRole = AccountRole.hospitalStaff;
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Register Hospital'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtl,
                      decoration: const InputDecoration(
                        labelText: 'Hospital Name',
                        hintText: 'e.g. Tikur Anbessa Hospital',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final trimmed = v.trim().toLowerCase();
                        final exists = hospitals.any(
                          (h) => h.name.trim().toLowerCase() == trimmed,
                        );
                        if (exists) {
                          return 'A hospital with this name is already registered';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: bedsCtl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Total Beds'),
                            validator: (v) =>
                                (v == null || int.tryParse(v) == null) ? 'Invalid' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: icuCtl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'ICU Beds'),
                            validator: (v) =>
                                (v == null || int.tryParse(v) == null) ? 'Invalid' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: ambCtl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Ambulances'),
                            validator: (v) =>
                                (v == null || int.tryParse(v) == null) ? 'Invalid' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: addressCtl,
                            decoration: const InputDecoration(labelText: 'District/Address'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: specCtl,
                      decoration: const InputDecoration(
                        labelText: 'Specialization / Medical Capability',
                        hintText: 'e.g. Trauma, orthopedics, emergency care',
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    // Optional Staff & Operator Registration
                    InkWell(
                      onTap: () => setDialogState(() => addStaff = !addStaff),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              addStaff ? Icons.check_box : Icons.check_box_outline_blank,
                              size: 18,
                              color: addStaff ? AppColors.brandRed : AppColors.inkSoft,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Register Initial Staff / Operator (Optional)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (addStaff) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: staffNameCtl,
                        decoration: const InputDecoration(
                          labelText: 'Staff Member Name',
                          hintText: 'e.g. Dr. Meron Gebre',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: staffEmailCtl,
                        decoration: const InputDecoration(
                          labelText: 'Staff Email / Login',
                          hintText: 'e.g. meron@hospital.et',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<AccountRole>(
                        value: staffRole,
                        decoration: const InputDecoration(labelText: 'Assigned Role'),
                        items: const [
                          DropdownMenuItem(
                            value: AccountRole.hospitalStaff,
                            child: Text('Hospital Staff (ER Triage / Doctor)'),
                          ),
                          DropdownMenuItem(
                            value: AccountRole.crew,
                            child: Text('Ambulance Crew (Paramedic)'),
                          ),
                          DropdownMenuItem(
                            value: AccountRole.dispatcher,
                            child: Text('Hospital Dispatcher (Station Operator)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => staffRole = val);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final trimmedName = nameCtl.text.trim();
                        final duplicate = hospitals.any(
                          (h) => h.name.trim().toLowerCase() == trimmedName.toLowerCase(),
                        );
                        if (duplicate) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hospital "$trimmedName" is already registered.'),
                              backgroundColor: AppColors.brandRed,
                            ),
                          );
                          return;
                        }
                        setDialogState(() => saving = true);
                        try {
                          await AdminRepository.instance.registerHospital(
                            name: trimmedName,
                            beds: int.parse(bedsCtl.text),
                            icuBeds: int.parse(icuCtl.text),
                            ambulanceCount: int.parse(ambCtl.text),
                            address: addressCtl.text.trim(),
                            location: addressCtl.text.trim(),
                            specialization: specCtl.text.trim(),
                          );
                          if (addStaff && staffNameCtl.text.trim().isNotEmpty) {
                            await AdminRepository.instance.registerHospitalStaff(
                              hospitalName: trimmedName,
                              fullName: staffNameCtl.text.trim(),
                              email: staffEmailCtl.text.trim().isEmpty
                                  ? '${staffNameCtl.text.trim().toLowerCase().replaceAll(' ', '.')}@hiwonet.et'
                                  : staffEmailCtl.text.trim(),
                              role: staffRole,
                            );
                          }
                          if (!context.mounted) return;
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                addStaff && staffNameCtl.text.trim().isNotEmpty
                                    ? '$trimmedName and staff account registered successfully.'
                                    : '$trimmedName successfully registered.',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          setDialogState(() => saving = false);
                          final cleanMsg = e.toString().replaceFirst('Exception: ', '');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(cleanMsg),
                              backgroundColor: AppColors.brandRed,
                            ),
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Register Hospital'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showRegisterAmbulanceDialog(List<HospitalRecord> hospitals) async {
    if (hospitals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please register a hospital first to act as a home base.'),
          backgroundColor: AppColors.brandRed,
        ),
      );
      return;
    }

    final unitCtl = TextEditingController(text: 'AMB-${4710 + DateTime.now().second}');
    String selectedBase = hospitals.first.name;
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Register Ambulance Unit'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: unitCtl,
                    decoration: const InputDecoration(
                      labelText: 'Callsign / Unit ID',
                      hintText: 'e.g. AMB-4715',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  Text('Home Base Station',
                      style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedBase,
                    isExpanded: true,
                    items: [
                      for (final h in hospitals)
                        DropdownMenuItem(
                          value: h.name,
                          child: Text(h.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedBase = v);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        try {
                          await AdminRepository.instance.registerAmbulance(
                            unitId: unitCtl.text.trim(),
                            homeBase: selectedBase,
                          );
                          if (!context.mounted) return;
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Unit ${unitCtl.text} assigned to $selectedBase.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          setDialogState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.brandRed,
                            ),
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Provision Unit'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showUpdateBedsDialog(HospitalRecord hospital) async {
    if (hospital.id.isEmpty) return;
    final bedsCtl = TextEditingController(text: '${hospital.beds}');
    final icuCtl = TextEditingController(text: '${hospital.icuBeds}');
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Update ${hospital.name} Beds'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bedsCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Regular Beds Available'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: icuCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'ICU Beds Available'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final b = int.tryParse(bedsCtl.text);
                        final icu = int.tryParse(icuCtl.text);
                        if (b == null || icu == null) return;
                        setDialogState(() => saving = true);
                        try {
                          await AdminRepository.instance.updateHospitalBeds(
                            hospitalId: hospital.id,
                            beds: b,
                            icuBeds: icu,
                          );
                          if (!context.mounted) return;
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Hospital bed capacity updated.')),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          setDialogState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.brandRed),
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HospitalRecord>>(
      stream: AdminRepository.instance.streamHospitals(),
      builder: (context, hospSnap) {
        final hospitals = hospSnap.data ?? AdminDemoData.hospitals;

        return StreamBuilder<List<AmbulanceRecord>>(
          stream: AdminRepository.instance.streamAmbulances(),
          builder: (context, ambSnap) {
            final ambulances = ambSnap.data ?? AdminDemoData.ambulances;

            final totalBeds = hospitals.fold(0, (sum, h) => sum + h.beds);
            final totalIcu = hospitals.fold(0, (sum, h) => sum + h.icuBeds);
            final totalAmbulances = ambulances.length;

            return AdminScaffold(
              selectedIndex: 3,
              title: 'Hospitals & Fleet',
              headerActions: [
                ElevatedButton.icon(
                  onPressed: () => _showRegisterHospitalDialog(hospitals),
                  icon: const Icon(Icons.add_business, size: 16),
                  label: const Text('Register Hospital'),
                ),
              ],
              child: LayoutBuilder(builder: (context, c) {
                final stacked = c.maxWidth < 900;
                final tables = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HospitalsCard(
                      hospitals: hospitals,
                      onEditHospital: _showUpdateBedsDialog,
                      onRegister: () => _showRegisterHospitalDialog(hospitals),
                      onAddStaff: _showAddStaffDialog,
                    ),
                    const SizedBox(height: 16),
                    _AmbulancesCard(
                      ambulances: ambulances,
                      onRegister: () => _showRegisterAmbulanceDialog(hospitals),
                    ),
                  ],
                );
                final capacity = _CapacityCard(
                  totalBeds: totalBeds,
                  icuBeds: totalIcu,
                  ambulances: totalAmbulances,
                );
                return SingleChildScrollView(
                  child: stacked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [capacity, const SizedBox(height: 16), tables],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: tables),
                            const SizedBox(width: 16),
                            SizedBox(width: 260, child: capacity),
                          ],
                        ),
                );
              }),
            );
          },
        );
      },
    );
  }
}

class _CapacityCard extends StatelessWidget {
  final int totalBeds;
  final int icuBeds;
  final int ambulances;

  const _CapacityCard({
    required this.totalBeds,
    required this.icuBeds,
    required this.ambulances,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network capacity',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 12),
            _stat('$totalBeds', 'Total Beds Available'),
            const SizedBox(height: 12),
            _stat('$icuBeds', 'ICU Beds Available'),
            const SizedBox(height: 12),
            _stat('$ambulances', 'Provisioned Ambulances'),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label,
              style: TextStyle(color: AppColors.inkSoft, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _HospitalsCard extends StatelessWidget {
  final List<HospitalRecord> hospitals;
  final ValueChanged<HospitalRecord> onEditHospital;
  final VoidCallback onRegister;
  final ValueChanged<HospitalRecord> onAddStaff;

  const _HospitalsCard({
    required this.hospitals,
    required this.onEditHospital,
    required this.onRegister,
    required this.onAddStaff,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Hospitals',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${hospitals.length} centers)',
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onRegister,
                  icon: const Icon(Icons.add_business, size: 14),
                  label: const Text('Register Hospital'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                headingRowHeight: 38,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 64,
                columns: const [
                  DataColumn(label: Text('Facility Name')),
                  DataColumn(label: Text('Location / District')),
                  DataColumn(label: Text('Specialization')),
                  DataColumn(label: Text('Regular Beds')),
                  DataColumn(label: Text('ICU')),
                  DataColumn(label: Text('Units')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Action')),
                ],
                rows: [
                  for (final h in hospitals)
                    DataRow(cells: [
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Text(
                            h.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.brandRed),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 190),
                              child: Text(
                                h.location,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 230),
                          child: Text(
                            h.specialization,
                            style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text('${h.beds}', style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text('${h.icuBeds}', style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text('${h.ambulanceCount}')),
                      DataCell(SimpleStatusPill(
                        label: h.active ? 'Active' : 'Inactive',
                        positive: h.active,
                      )),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => onEditHospital(h),
                              child: const Text('Update Beds',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 4),
                            TextButton.icon(
                              onPressed: () => onAddStaff(h),
                              icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                              label: const Text('Add Staff',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ]),
                ],
              ),
            ),
            if (hospitals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No hospitals registered yet.',
                    style: TextStyle(color: AppColors.inkSoft)),
              ),
          ],
        ),
      ),
    );
  }
}

class _AmbulancesCard extends StatelessWidget {
  final List<AmbulanceRecord> ambulances;
  final VoidCallback onRegister;

  const _AmbulancesCard({required this.ambulances, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Ambulances',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onRegister,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Register Unit'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                headingRowHeight: 36,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 52,
                columns: const [
                  DataColumn(label: Text('Unit ID')),
                  DataColumn(label: Text('Home Base Station')),
                  DataColumn(label: Text('Status')),
                ],
                rows: [
                  for (final a in ambulances)
                    DataRow(cells: [
                      DataCell(Text(a.unitId,
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(a.homeBase)),
                      DataCell(SimpleStatusPill(label: a.status)),
                    ]),
                ],
              ),
            ),
            if (ambulances.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No ambulances registered yet.',
                    style: TextStyle(color: AppColors.inkSoft)),
              ),
          ],
        ),
      ),
    );
  }
}
