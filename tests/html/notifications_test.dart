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

      /*
      // Sporadically flaky on Mac Chrome. Uncomment when Issue 8482 is fixed.
      test('construct notification', () {
        var note = new Notification('this is a notification');
        var note2 = new Notification('another notificiation', titleDir: 'foo');
      });
      */
    }
  });
}

