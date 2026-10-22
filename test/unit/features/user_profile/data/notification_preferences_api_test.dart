import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../helpers/helpers.dart';

class _Api extends Mock implements ApiBaseService {}

/// The body the Zedu API returns from GET/PUT /users/notification-preferences.
const _apiBody = <String, dynamic>{
  'id': 'pref-1',
  'user_id': 'user-1',
  'notify_about': {'Option': 'direct_messages_mentions'},
  'notification_schedule': true,
  'from_hour': '08:00',
  'to_hour': '20:30',
  'notification_method_email': true,
};

void main() {
  const config = AppConfig(
    apiBaseUrl: 'https://api.example.test',
    usesMockData: false,
  );

  group('notification preferences API (#586)', () {
    test('loads from GET /users/notification-preferences', () async {
      final api = _Api();
      when(
        () => api.get<Map<String, dynamic>>(path: any(named: 'path')),
      ).thenAnswer(
        (_) async => ApiResponseModel<Map<String, dynamic>>(
          data: {'data': _apiBody},
          statusCode: 200,
        ),
      );

      final prefs = await UserProfileRemoteDataSourceImpl(
        config: config,
        apiBaseService: api,
      ).getNotificationPreferences();

      verify(
        () => api.get<Map<String, dynamic>>(
          path: '/users/notification-preferences',
        ),
      ).called(1);
      expect(prefs.mode, NotificationMode.mentionsOnly);
      expect(prefs.fromTime, '08:00 AM');
      expect(prefs.toTime, '08:30 PM');
      expect(prefs.emailNotifications, isTrue);
    });

    test(
      'saves with PUT /users/notification-preferences in the API shape',
      () async {
        final api = _Api();
        when(
          () => api.put<Map<String, dynamic>>(
            path: any(named: 'path'),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => ApiResponseModel<Map<String, dynamic>>(
            data: {'data': _apiBody},
            statusCode: 200,
          ),
        );

        final saved =
            await UserProfileRemoteDataSourceImpl(
              config: config,
              apiBaseService: api,
            ).updateNotificationPreferences(
              const NotificationPreferences(
                mode: NotificationMode.mentionsOnly,
                fromTime: '08:00 AM',
                toTime: '08:30 PM',
                useDesktopSettings: false,
                emailNotifications: true,
              ),
            );

        final body =
            verify(
                  () => api.put<Map<String, dynamic>>(
                    path: '/users/notification-preferences',
                    data: captureAny(named: 'data'),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(body, {
          'notify_about': {'Option': 'direct_messages_mentions'},
          'notification_schedule': true,
          'from_hour': '08:00',
          'to_hour': '20:30',
          'notification_method_email': true,
        });
        verifyNever(
          () => api.patch<Map<String, dynamic>>(
            path: any(named: 'path'),
            data: any(named: 'data'),
          ),
        );
        // The API has no "use desktop settings" field; the choice is kept.
        expect(saved.useDesktopSettings, isFalse);
      },
    );
  });

  group('NotificationPreferencesModel API mapping (#586)', () {
    test('maps every notify_about option both ways', () {
      const cases = {
        'all_new_messages': NotificationMode.allMessages,
        'direct_messages_mentions': NotificationMode.mentionsOnly,
        'nothing': NotificationMode.none,
      };
      cases.forEach((option, mode) {
        final model = NotificationPreferencesModel.fromApiJson({
          'notify_about': {'Option': option},
        });
        expect(model.mode, mode);
        expect(model.toApiJson()['notify_about'], {'Option': option});
      });
    });

    test('converts midnight and noon between 24-hour and 12-hour time', () {
      final model = NotificationPreferencesModel.fromApiJson({
        'from_hour': '00:00',
        'to_hour': '12:15',
      });
      expect(model.fromTime, '12:00 AM');
      expect(model.toTime, '12:15 PM');
      expect(model.toApiJson()['from_hour'], '00:00');
      expect(model.toApiJson()['to_hour'], '12:15');
    });

    test('falls back to defaults for missing or malformed values', () {
      final model = NotificationPreferencesModel.fromApiJson({
        'notify_about': 'not-an-object',
        'from_hour': '25:00',
      });
      expect(model.mode, NotificationMode.allMessages);
      expect(model.fromTime, '12:00 AM');
      expect(model.toTime, '11:00 PM');
      expect(model.emailNotifications, isFalse);
    });

    test('turns the schedule off when the window starts and ends together', () {
      const anyTime = NotificationPreferencesModel(
        mode: NotificationMode.allMessages,
        fromTime: '12:00 AM',
        toTime: '12:00 AM',
        useDesktopSettings: true,
        emailNotifications: false,
      );
      expect(anyTime.toApiJson()['notification_schedule'], isFalse);
    });
  });
}
