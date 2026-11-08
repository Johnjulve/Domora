import 'package:domora/core/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalNotificationService service;

  setUp(() {
    service = LocalNotificationService();
  });

  group('NotificationService Contract & In-Memory Harness Tests', () {
    test('Initialization runs safely and marks service as initialized', () async {
      expect(service.isInitialized, false);

      await service.initialize();

      expect(service.isInitialized, true);
    });

    test('scheduleDailyHouseholdDigest schedules digest with ID 1001 and tracks payload',
        () async {
      await service.initialize();

      await service.scheduleDailyHouseholdDigest(
        hour: 8,
        minute: 30,
        title: 'Good morning from Domora',
        body: 'Your household digest and daily sanctuary focus are ready.',
      );

      expect(service.scheduledDigests.containsKey(1001), true);
      final digest = service.scheduledDigests[1001]!;
      expect(digest.id, 1001);
      expect(digest.hour, 8);
      expect(digest.minute, 30);
      expect(digest.title, 'Good morning from Domora');
      expect(digest.body, 'Your household digest and daily sanctuary focus are ready.');

      // Rescheduling updates the payload
      await service.scheduleDailyHouseholdDigest(
        hour: 9,
        minute: 15,
        title: 'Morning Sanctuary Digest',
        body: 'Updated reminder time.',
      );

      final updated = service.scheduledDigests[1001]!;
      expect(updated.hour, 9);
      expect(updated.minute, 15);
      expect(updated.title, 'Morning Sanctuary Digest');
    });

    test('scheduleTaskDueReminder records scheduled task reminder with date and payload',
        () async {
      await service.initialize();
      final due = DateTime(2026, 11, 20, 14, 0);

      await service.scheduleTaskDueReminder(
        id: 101,
        title: 'Inspect Water Heater Anode Rod',
        body: 'Annual preventive maintenance due today.',
        scheduledDate: due,
      );

      expect(service.scheduledTasks.containsKey(101), true);
      final taskReminder = service.scheduledTasks[101]!;
      expect(taskReminder.id, 101);
      expect(taskReminder.title, 'Inspect Water Heater Anode Rod');
      expect(taskReminder.body, 'Annual preventive maintenance due today.');
      expect(taskReminder.scheduledDate, due);
    });

    test('showImmediateNotice tracks immediate on-device notice safely', () async {
      await service.initialize();

      await service.showImmediateNotice(
        id: 201,
        title: 'Backup Archive Generated',
        body: 'Encrypted snapshot exported with SHA-256 integrity fingerprint.',
      );

      expect(service.immediateNotices.containsKey(201), true);
      final notice = service.immediateNotices[201]!;
      expect(notice.id, 201);
      expect(notice.title, 'Backup Archive Generated');
      expect(notice.body, 'Encrypted snapshot exported with SHA-256 integrity fingerprint.');
    });

    test('cancel removes specific notification from active tracking', () async {
      await service.initialize();

      await service.scheduleDailyHouseholdDigest(
        hour: 7,
        minute: 0,
        title: 'Digest',
        body: 'Body',
      );
      await service.scheduleTaskDueReminder(
        id: 50,
        title: 'Task Due',
        body: 'Body',
        scheduledDate: DateTime.now().add(const Duration(hours: 2)),
      );
      await service.showImmediateNotice(
        id: 99,
        title: 'Immediate',
        body: 'Body',
      );

      expect(service.scheduledDigests.containsKey(1001), true);
      expect(service.scheduledTasks.containsKey(50), true);
      expect(service.immediateNotices.containsKey(99), true);

      // Cancel task 50
      await service.cancel(50);
      expect(service.scheduledTasks.containsKey(50), false);
      expect(service.scheduledDigests.containsKey(1001), true);

      // Cancel digest 1001
      await service.cancel(1001);
      expect(service.scheduledDigests.containsKey(1001), false);

      // Cancel immediate 99
      await service.cancel(99);
      expect(service.immediateNotices.containsKey(99), false);
    });

    test('cancelAll clears all scheduled digests, tasks, and immediate notices', () async {
      await service.initialize();

      await service.scheduleDailyHouseholdDigest(
        hour: 8,
        minute: 0,
        title: 'Digest',
        body: 'Body',
      );
      await service.scheduleTaskDueReminder(
        id: 60,
        title: 'Task A',
        body: 'Body A',
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
      );
      await service.scheduleTaskDueReminder(
        id: 61,
        title: 'Task B',
        body: 'Body B',
        scheduledDate: DateTime.now().add(const Duration(days: 2)),
      );
      await service.showImmediateNotice(
        id: 70,
        title: 'Immediate notice',
        body: 'Notice',
      );

      expect(service.scheduledDigests.length, 1);
      expect(service.scheduledTasks.length, 2);
      expect(service.immediateNotices.length, 1);

      await service.cancelAll();

      expect(service.scheduledDigests.isEmpty, true);
      expect(service.scheduledTasks.isEmpty, true);
      expect(service.immediateNotices.isEmpty, true);
    });

    test('All methods operate safely without throwing on unsupported platform or error state',
        () async {
      // Create fresh uninitialized service to verify resilience
      final rawService = LocalNotificationService();

      expect(
        () async => await rawService.scheduleDailyHouseholdDigest(
          hour: 6,
          minute: 30,
          title: 'Morning',
          body: 'Digest',
        ),
        returnsNormally,
      );

      expect(
        () async => await rawService.scheduleTaskDueReminder(
          id: 999,
          title: 'Task',
          body: 'Desc',
          scheduledDate: DateTime.now(),
        ),
        returnsNormally,
      );

      expect(
        () async => await rawService.showImmediateNotice(
          id: 888,
          title: 'Notice',
          body: 'Immediate',
        ),
        returnsNormally,
      );

      expect(
        () async => await rawService.cancel(999),
        returnsNormally,
      );

      expect(
        () async => await rawService.cancelAll(),
        returnsNormally,
      );
    });
  });
}
