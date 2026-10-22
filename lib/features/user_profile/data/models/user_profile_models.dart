import 'package:zedu/features/features.dart';

class ProfileAccountModel extends ProfileAccount {
  const ProfileAccountModel({
    required super.name,
    required super.email,
    required super.timezone,
    super.avatarUrl,
  });

  factory ProfileAccountModel.fromJson(Map<String, dynamic> json) {
    return ProfileAccountModel(
      name: json['name'] as String? ?? 'Anonymous user',
      email: json['email'] as String? ?? 'anonymoususer@email.com',
      timezone: json['timezone'] as String? ?? 'Africa/Lagos',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'timezone': timezone,
    'avatar_url': avatarUrl,
  };
}

class NotificationPreferencesModel extends NotificationPreferences {
  const NotificationPreferencesModel({
    required super.mode,
    required super.fromTime,
    required super.toTime,
    required super.useDesktopSettings,
    required super.emailNotifications,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      mode: _modeFromJson(json['mode'] as String?),
      fromTime: json['from_time'] as String? ?? '12:00 AM',
      toTime: json['to_time'] as String? ?? '11:00 PM',
      useDesktopSettings: json['use_desktop_settings'] as bool? ?? true,
      emailNotifications: json['email_notifications'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'from_time': fromTime,
    'to_time': toTime,
    'use_desktop_settings': useDesktopSettings,
    'email_notifications': emailNotifications,
  };

  /// Reads the Zedu API's `GET /users/notification-preferences` body (#586).
  ///
  /// The API stores `notify_about` as `{ "Option": "..." }`, 24-hour
  /// `from_hour`/`to_hour`, and `notification_method_email`. It has no
  /// "use desktop settings" flag, so [useDesktopSettings] is kept on the
  /// device and passed in.
  factory NotificationPreferencesModel.fromApiJson(
    Map<String, dynamic> json, {
    bool useDesktopSettings = true,
  }) {
    final notifyAbout = json['notify_about'];
    final option = notifyAbout is Map ? notifyAbout['Option'] as String? : null;
    return NotificationPreferencesModel(
      mode: switch (option) {
        'direct_messages_mentions' => NotificationMode.mentionsOnly,
        'nothing' => NotificationMode.none,
        _ => NotificationMode.allMessages,
      },
      fromTime: _to12Hour(json['from_hour'] as String?, '12:00 AM'),
      toTime: _to12Hour(json['to_hour'] as String?, '11:00 PM'),
      useDesktopSettings: useDesktopSettings,
      emailNotifications: json['notification_method_email'] as bool? ?? false,
    );
  }

  /// The body for `PUT /users/notification-preferences` (#586).
  Map<String, dynamic> toApiJson() {
    final from = _to24Hour(fromTime);
    final to = _to24Hour(toTime);
    return {
      'notify_about': {
        'Option': switch (mode) {
          NotificationMode.allMessages => 'all_new_messages',
          NotificationMode.mentionsOnly => 'direct_messages_mentions',
          NotificationMode.none => 'nothing',
        },
      },
      // A window that starts and ends at the same time means "any time".
      'notification_schedule': from != to,
      'from_hour': from,
      'to_hour': to,
      'notification_method_email': emailNotifications,
    };
  }

  /// "08:00" or "20:30" (API) → "08:00 AM" / "08:30 PM" (this app).
  static String _to12Hour(String? value, String fallback) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})$',
    ).firstMatch(value?.trim() ?? '');
    if (match == null) return fallback;
    final hour = int.parse(match.group(1)!);
    if (hour > 23) return fallback;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${hour12.toString().padLeft(2, '0')}:${match.group(2)} $suffix';
  }

  /// "08:00 AM" / "8:30 PM" (this app) → "08:00" / "20:30" (API).
  static String _to24Hour(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$',
    ).firstMatch(value.trim());
    if (match == null) return '00:00';
    var hour = int.parse(match.group(1)!) % 12;
    if (match.group(3)!.toUpperCase() == 'PM') hour += 12;
    return '${hour.toString().padLeft(2, '0')}:${match.group(2)}';
  }

  static NotificationMode _modeFromJson(String? value) {
    return switch (value) {
      'mentionsOnly' || 'mentions_only' => NotificationMode.mentionsOnly,
      'none' => NotificationMode.none,
      _ => NotificationMode.allMessages,
    };
  }
}

class OrganizationProfileModel extends OrganizationProfile {
  const OrganizationProfileModel({
    required super.id,
    required super.name,
    required super.natureOfBusiness,
    required super.country,
  });

  factory OrganizationProfileModel.fromJson(Map<String, dynamic> json) {
    return OrganizationProfileModel(
      id: json['id'] as String? ?? '019700db-4e22-7f90-a20e-f9116291ef24',
      name: json['name'] as String? ?? 'Anonymous user',
      natureOfBusiness:
          json['nature_of_business'] as String? ?? 'Design agency',
      country: json['country'] as String? ?? 'Nigeria',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nature_of_business': natureOfBusiness,
    'country': country,
  };
}

class SecuritySessionModel extends SecuritySession {
  const SecuritySessionModel({
    required super.device,
    required super.location,
    required super.date,
    required super.lastActive,
    required super.status,
  });

  factory SecuritySessionModel.fromJson(Map<String, dynamic> json) {
    return SecuritySessionModel(
      device: json['device'] as String? ?? 'Chrome',
      location: json['location'] as String? ?? 'Lagos',
      date: json['date'] as String? ?? 'May 8, 2026 1:07 PM',
      lastActive: json['last_active'] as String? ?? 'May 8, 2026 3:07 PM',
      status: json['status'] as String? ?? 'Active',
    );
  }
}

class TeamMemberModel extends TeamMember {
  const TeamMemberModel({
    required super.id,
    required super.email,
    required super.role,
    required super.dateJoined,
    required super.status,
    super.name,
    super.avatarUrl,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      id: json['id'] as String? ?? 'member-1',
      email: json['email'] as String? ?? 'anonymoususer@gmail.com',
      role: json['role'] as String? ?? 'Administrator',
      dateJoined: json['date_joined'] as String? ?? 'May 3, 2026',
      status: _statusFromJson(json['status'] as String?),
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  static TeamMemberStatus _statusFromJson(String? value) {
    return switch (value) {
      'pending' => TeamMemberStatus.pending,
      'inactive' => TeamMemberStatus.inactive,
      _ => TeamMemberStatus.active,
    };
  }
}

class RolePermissionModel extends RolePermission {
  const RolePermissionModel({
    required super.role,
    required super.description,
    required super.permissions,
  });

  factory RolePermissionModel.fromJson(Map<String, dynamic> json) {
    return RolePermissionModel(
      role: json['role'] as String? ?? 'User',
      description: json['description'] as String? ?? '',
      permissions:
          (json['permissions'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}

class BillingInfoModel extends BillingInfo {
  const BillingInfoModel({
    required super.plan,
    required super.description,
    super.paymentHistory,
  });

  factory BillingInfoModel.fromJson(Map<String, dynamic> json) {
    return BillingInfoModel(
      plan: json['plan'] as String? ?? 'Zedu Free',
      description: json['description'] as String? ?? '',
      paymentHistory:
          (json['payment_history'] as List<dynamic>?)
              ?.map(
                (e) => PaymentRecordModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}

class PaymentRecordModel extends PaymentRecord {
  const PaymentRecordModel({
    required super.id,
    required super.description,
    required super.amount,
    required super.date,
    required super.status,
  });

  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) {
    return PaymentRecordModel(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? 'Subscription Payment',
      amount: json['amount'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}
