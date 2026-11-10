import '../data/network_stats.dart';

/// Domain models for the Admin Panel (Login, Dashboard, User Management,
/// Hospital & Ambulance Registry, System / Audit Logs). This panel is the
/// "reasoned addition" screen set: the dispatcher spec defines four
/// operating roles but never says who provisions them, so these models
/// exist to make that provisioning flow concrete.

enum AccountRole { caller, crew, hospitalStaff, dispatcher, admin }

extension AccountRoleLabel on AccountRole {
  String get label {
    switch (this) {
      case AccountRole.caller:
        return 'Caller';
      case AccountRole.crew:
        return 'Crew';
      case AccountRole.hospitalStaff:
        return 'Hospital Staff';
      case AccountRole.dispatcher:
        return 'Dispatcher';
      case AccountRole.admin:
        return 'Admin';
    }
  }
}

enum AccountStatus { active, suspended }

class UserAccount {
  final String id;
  final String name;
  final AccountRole role;
  final AccountStatus status;
  final String lastActiveLabel;
  final String email;
  final String employeeId;
  final String radioCallsign;
  final String dispatchCenter;
  final String? photoUrl;

  const UserAccount({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.lastActiveLabel,
    this.email = '',
    this.employeeId = '',
    this.radioCallsign = '',
    this.dispatchCenter = '',
    this.photoUrl,
  });

  UserAccount copyWith({AccountStatus? status}) => UserAccount(
        id: id,
        name: name,
        role: role,
        status: status ?? this.status,
        lastActiveLabel: lastActiveLabel,
        email: email,
        employeeId: employeeId,
        radioCallsign: radioCallsign,
        dispatchCenter: dispatchCenter,
        photoUrl: photoUrl,
      );
}

class RegistrationRequest {
  final String id;
  final String fullName;
  final String employeeId;
  final String dispatchCenter;
  final String radioCallsign;
  final String email;
  final String password;
  final String status;
  final DateTime createdAt;

  const RegistrationRequest({
    required this.id,
    required this.fullName,
    required this.employeeId,
    required this.dispatchCenter,
    required this.radioCallsign,
    required this.email,
    this.password = '',
    required this.status,
    required this.createdAt,
  });

  factory RegistrationRequest.fromMap(String id, Map<String, dynamic> data) {
    DateTime created = DateTime.now();
    final raw = data['createdAt'];
    if (raw is DateTime) {
      created = raw;
    } else if (raw != null && raw.toString().isNotEmpty) {
      // Handles Firestore Timestamp dynamically or ISO strings
      try {
        if (raw.runtimeType.toString().contains('Timestamp')) {
          created = (raw as dynamic).toDate();
        } else {
          created = DateTime.tryParse(raw.toString()) ?? DateTime.now();
        }
      } catch (_) {
        created = DateTime.now();
      }
    }
    return RegistrationRequest(
      id: id,
      fullName: data['fullName'] ?? data['name'] ?? 'Dispatcher Applicant',
      employeeId: data['employeeId'] ?? 'DSP-PENDING',
      dispatchCenter: data['dispatchCenter'] ?? 'Addis Ababa Central',
      radioCallsign: data['radioCallsign'] ?? 'N/A',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: created,
    );
  }
}

class HospitalRecord {
  final String id;
  final String name;
  final String location;
  final String specialization;
  final int beds;
  final int icuBeds;
  final int ambulanceCount;
  final bool active;

  const HospitalRecord({
    this.id = '',
    required this.name,
    this.location = 'Addis Ababa',
    this.specialization = 'General & Emergency Care',
    required this.beds,
    required this.icuBeds,
    required this.ambulanceCount,
    this.active = true,
  });
}

class AmbulanceRecord {
  final String unitId;
  final String homeBase;
  final String status; // e.g. "In Service"

  const AmbulanceRecord({
    required this.unitId,
    required this.homeBase,
    required this.status,
  });
}

enum AuditAction { roleChange, registration, suspension, signIn, dispatch, incident }

extension AuditActionLabel on AuditAction {
  String get label {
    switch (this) {
      case AuditAction.roleChange:
        return 'Role changes';
      case AuditAction.registration:
        return 'Registrations';
      case AuditAction.suspension:
        return 'Suspensions';
      case AuditAction.signIn:
        return 'Sign-ins';
      case AuditAction.dispatch:
        return 'Dispatches';
      case AuditAction.incident:
        return 'Incidents';
    }
  }
}

class AuditLogEntry {
  final String timestamp;
  final String actor;
  final AuditAction action;
  final String description;
  final String target;

  const AuditLogEntry({
    required this.timestamp,
    required this.actor,
    required this.action,
    required this.description,
    required this.target,
  });
}

class ActivityEntry {
  final String title;
  final String timeAgo;
  const ActivityEntry({required this.title, required this.timeAgo});
}

/// Seeded demo dataset. Role-breakdown counts intentionally sum to
/// [NetworkStats.totalUsers] (268 + 22 + 17 + 5 = 312) so the Admin
/// Dashboard's "Users" stat and the User Management role breakdown never
/// visibly disagree with each other.
class AdminDemoData {
  AdminDemoData._();

  static const roleBreakdown = <AccountRole, int>{
    AccountRole.caller: 268,
    AccountRole.crew: 22,
    AccountRole.hospitalStaff: 17,
    AccountRole.dispatcher: 5,
  };

  static const int totalUsers = NetworkStats.totalUsers;
  static const int totalHospitals = NetworkStats.totalHospitals;
  static const int totalAmbulances = NetworkStats.totalAmbulances;

  static const users = <UserAccount>[
    UserAccount(
      id: 'u-1',
      name: 'Dr. Sara Tadesse',
      role: AccountRole.hospitalStaff,
      status: AccountStatus.active,
      lastActiveLabel: '10m ago',
    ),
    UserAccount(
      id: 'u-2',
      name: 'Marcus Reyes',
      role: AccountRole.crew,
      status: AccountStatus.active,
      lastActiveLabel: '1h ago',
    ),
    UserAccount(
      id: 'u-3',
      name: 'Meron A.',
      role: AccountRole.dispatcher,
      status: AccountStatus.active,
      lastActiveLabel: 'Just now',
    ),
    UserAccount(
      id: 'u-4',
      name: 'Sara Getachew',
      role: AccountRole.caller,
      status: AccountStatus.active,
      lastActiveLabel: '2d ago',
    ),
    UserAccount(
      id: 'u-5',
      name: 'Yonas Bekele',
      role: AccountRole.caller,
      status: AccountStatus.suspended,
      lastActiveLabel: '6d ago',
    ),
  ];

  static const hospitals = <HospitalRecord>[
    HospitalRecord(
      id: 'hosp-01',
      name: 'ALERT Comprehensive Specialized Hospital',
      location: 'Kolfe Keranyo',
      specialization: 'Major public trauma, orthopedics, neurosurgery, and dermatology center',
      beds: 85,
      icuBeds: 18,
      ambulanceCount: 5,
    ),
    HospitalRecord(
      id: 'hosp-02',
      name: 'Tikur Anbessa Specialized Hospital (Black Lion Hospital)',
      location: 'Lideta / Central Addis Ababa',
      specialization: "Country's largest public university teaching hospital",
      beds: 120,
      icuBeds: 24,
      ambulanceCount: 8,
    ),
    HospitalRecord(
      id: 'hosp-03',
      name: "St. Paul's Hospital Millennium Medical College",
      location: 'Gulele Sub-city',
      specialization: 'Large public referral and teaching hospital',
      beds: 110,
      icuBeds: 20,
      ambulanceCount: 6,
    ),
    HospitalRecord(
      id: 'hosp-04',
      name: 'AaBET Hospital (Addis Ababa Burn, Emergency and Trauma)',
      location: 'Dej Zewdu Aba Koran St',
      specialization: 'Dedicated public trauma and emergency center',
      beds: 65,
      icuBeds: 16,
      ambulanceCount: 4,
    ),
    HospitalRecord(
      id: 'hosp-05',
      name: 'Myungsung Christian Medical Centre (MCM / Korean Hospital)',
      location: 'Gerji, CMC area',
      specialization: 'Private tertiary hospital with trauma, orthopedics, and neurosurgery',
      beds: 55,
      icuBeds: 12,
      ambulanceCount: 3,
    ),
    HospitalRecord(
      id: 'hosp-06',
      name: 'Dream Orthopedics, Trauma and Spine Specialty Center',
      location: 'Bole / Unnamed Road',
      specialization: 'Specialized private trauma, orthopedics, and spine care',
      beds: 35,
      icuBeds: 8,
      ambulanceCount: 2,
    ),
    HospitalRecord(
      id: 'hosp-07',
      name: 'Nordic Medical Centre',
      location: 'Kebele 01, House No. 1244, Bole Sub City',
      specialization: '24/7 private emergency and medical center',
      beds: 34,
      icuBeds: 8,
      ambulanceCount: 4,
    ),
    HospitalRecord(
      id: 'hosp-08',
      name: 'Bethesda American Medical Plaza (American Medical Center)',
      location: 'Opposite Capital Hotel',
      specialization: 'JCI-accredited private adult emergency and medical facility',
      beds: 28,
      icuBeds: 6,
      ambulanceCount: 2,
    ),
    HospitalRecord(
      id: 'hosp-09',
      name: 'Yekatit 12 Hospital Medical College',
      location: 'Arada Sub-city',
      specialization: 'Public general and emergency hospital',
      beds: 75,
      icuBeds: 14,
      ambulanceCount: 4,
    ),
    HospitalRecord(
      id: 'hosp-10',
      name: 'Zewditu Memorial Hospital',
      location: 'Taitu Street, Kirkos Sub-city',
      specialization: 'Public general medicine, surgery, and emergency care',
      beds: 50,
      icuBeds: 10,
      ambulanceCount: 3,
    ),
    HospitalRecord(
      id: 'hosp-11',
      name: 'Menelik II Referral Hospital',
      location: 'Arada Sub-city',
      specialization: 'Historic public general and specialized hospital',
      beds: 60,
      icuBeds: 10,
      ambulanceCount: 3,
    ),
    HospitalRecord(
      id: 'hosp-12',
      name: 'Ras Desta Damtew Memorial Hospital',
      location: 'Addis Ketema Sub-city',
      specialization: 'Public hospital with orthopedic and trauma care',
      beds: 48,
      icuBeds: 8,
      ambulanceCount: 3,
    ),
    HospitalRecord(
      id: 'hosp-13',
      name: 'Armed Forces Comprehensive Specialized Hospital (Milite / Princess Tsehai)',
      location: 'Lideta',
      specialization: 'Major military and referral hospital',
      beds: 95,
      icuBeds: 18,
      ambulanceCount: 5,
    ),
    HospitalRecord(
      id: 'hosp-14',
      name: 'Federal Police Hospital',
      location: 'Addis Ababa',
      specialization: 'Public/institutional emergency and general hospital',
      beds: 52,
      icuBeds: 10,
      ambulanceCount: 4,
    ),
    HospitalRecord(
      id: 'hosp-15',
      name: 'St. Peter’s Specialized Hospital',
      location: 'Shiromeda, Addis Ketema',
      specialization: 'Specialized referral hospital',
      beds: 58,
      icuBeds: 12,
      ambulanceCount: 3,
    ),
    HospitalRecord(
      id: 'hosp-16',
      name: 'Amanuel Mental Specialized Hospital',
      location: 'Addis Ketema Sub-city',
      specialization: 'Public specialized psychiatric and mental health center',
      beds: 80,
      icuBeds: 6,
      ambulanceCount: 2,
    ),
    HospitalRecord(
      id: 'hosp-17',
      name: 'Gandeme Metasebiya Hospital (Gandhi Memorial Hospital)',
      location: 'Kazanchis / Kirkos',
      specialization: 'Specialized maternal and general hospital',
      beds: 46,
      icuBeds: 8,
      ambulanceCount: 3,
    ),
    HospitalRecord(
      id: 'hosp-18',
      name: 'St. Gabriel General Hospital',
      location: 'Bole Sub-city',
      specialization: 'Private 24-hour general hospital',
      beds: 42,
      icuBeds: 8,
      ambulanceCount: 3,
    ),
    HospitalRecord(
      id: 'hosp-19',
      name: 'Ethio Tebib Hospital',
      location: 'Sefere Selam / Mexico Area',
      specialization: 'Private multi-specialty general hospital',
      beds: 38,
      icuBeds: 6,
      ambulanceCount: 2,
    ),
    HospitalRecord(
      id: 'hosp-20',
      name: 'Kadisco General Hospital',
      location: 'Saris / Gerji Roba',
      specialization: 'Private general hospital with 24-hour emergency and pediatrics',
      beds: 36,
      icuBeds: 6,
      ambulanceCount: 3,
    ),
    HospitalRecord(
      id: 'hosp-21',
      name: 'Hallelujah General Hospital',
      location: 'Piassa',
      specialization: 'Private general medical and surgical hospital',
      beds: 40,
      icuBeds: 8,
      ambulanceCount: 2,
    ),
    HospitalRecord(
      id: 'hosp-22',
      name: 'Landmark General Hospital',
      location: 'Kirkos / Bole Road',
      specialization: 'Private general hospital',
      beds: 32,
      icuBeds: 6,
      ambulanceCount: 2,
    ),
    HospitalRecord(
      id: 'hosp-23',
      name: 'Addis Hiwot Hospital',
      location: 'Haya Hulet, Bole Sub-city',
      specialization: 'Private general hospital',
      beds: 35,
      icuBeds: 6,
      ambulanceCount: 2,
    ),
    HospitalRecord(
      id: 'hosp-24',
      name: 'Teklehaimanot General Hospital',
      location: 'Addis Ababa',
      specialization: 'Private general and specialty hospital',
      beds: 38,
      icuBeds: 6,
      ambulanceCount: 2,
    ),
    HospitalRecord(
      id: 'hosp-25',
      name: 'Balcha Hospital',
      location: 'Kirkos / Lideta area',
      specialization: 'Private/mission-affiliated general hospital',
      beds: 44,
      icuBeds: 8,
      ambulanceCount: 2,
    ),
    HospitalRecord(
      id: 'hosp-26',
      name: 'Nucleus General Hospital',
      location: 'Mekanissa, German Square',
      specialization: 'Private 24-hour general hospital',
      beds: 30,
      icuBeds: 5,
      ambulanceCount: 2,
    ),
    HospitalRecord(
      id: 'hosp-27',
      name: 'Girum Hospital',
      location: 'Addis Ketema, near Medhanialem High School',
      specialization: 'Private general and surgical hospital',
      beds: 36,
      icuBeds: 7,
      ambulanceCount: 2,
    ),
    HospitalRecord(
      id: 'hosp-28',
      name: 'Yanet General Hospital (Addis Ababa)',
      location: 'Derartu Tulu Square, Ayat',
      specialization: 'Private general and trauma-focused facility',
      beds: 35,
      icuBeds: 6,
      ambulanceCount: 2,
    ),
  ];

  static const ambulances = <AmbulanceRecord>[
    AmbulanceRecord(unitId: 'AMB-4712', homeBase: "St. Luke's", status: 'In Service'),
    AmbulanceRecord(unitId: 'AMB-4713', homeBase: 'Nordic Medical Centre', status: 'In Service'),
  ];

  static const recentActivity = <ActivityEntry>[
    ActivityEntry(title: 'Nordic Medical Centre registered', timeAgo: '2h ago by you'),
    ActivityEntry(title: 'Marcus Reyes → role: Crew', timeAgo: '6h ago by you'),
    ActivityEntry(title: '1 account suspended', timeAgo: 'Yesterday by you'),
  ];

  static const auditLog = <AuditLogEntry>[
    AuditLogEntry(
      timestamp: 'Sep 3, 09:12',
      actor: 'Meron A. (Admin)',
      action: AuditAction.registration,
      description: 'Registered hospital',
      target: 'Nordic Medical Centre',
    ),
    AuditLogEntry(
      timestamp: 'Sep 3, 04:07',
      actor: 'Meron A. (Admin)',
      action: AuditAction.roleChange,
      description: 'Role changed',
      target: 'Marcus Reyes → Crew',
    ),
    AuditLogEntry(
      timestamp: 'Sep 2, 21:40',
      actor: 'Meron A. (Admin)',
      action: AuditAction.suspension,
      description: 'Suspended account',
      target: 'Yonas Bekele',
    ),
    AuditLogEntry(
      timestamp: 'Sep 2, 15:02',
      actor: 'System',
      action: AuditAction.registration,
      description: 'Registered ambulance',
      target: 'AMB-4713',
    ),
    AuditLogEntry(
      timestamp: 'Sep 1, 08:55',
      actor: 'Meron A. (Admin)',
      action: AuditAction.signIn,
      description: 'Signed in (2FA)',
      target: 'admin.hiwonet.et',
    ),
  ];
}
