library NotificationsTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(NotificationCenter.supported, true);
    });
  });

  group('unsupported_throws', () {
    test('createNotification', () {
      var expectation = NotificationCenter.supported ? returnsNormally : throws;
      expect(() { window.notifications.createNotification; }, expectation);
    });
  });

  group('webkitNotifications', () {
    if (NotificationCenter.supported) {
      test('DomException', () {
        try {
          window.notifications.createNotification('', '', '');
        } on DomException catch (e) {
          expect(e.name, DomException.SECURITY);
        }
      });
    }
  });
}

