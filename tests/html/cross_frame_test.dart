library CrossFrameTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  var isWindow = predicate((x) => x is Window, 'is a Window');
  var isLocalWindow = predicate((x) => x is LocalWindow, 'is a LocalWindow');
  var isLocation = predicate((x) => x is Location, 'is a Location');
  var isLocalLocation =
      predicate((x) => x is LocalLocation, 'is a LocalLocation');
  var isHistory = predicate((x) => x is History, 'is a History');
  var isLocalHistory = predicate((x) => x is LocalHistory, 'is a LocalHistory');

  final iframe = new Element.tag('iframe');
  document.body.nodes.add(iframe);

  test('window', () {
      expect(window, isLocalWindow);
      expect(window.document, document);
    });

  test('iframe', () {
      final frameWindow = iframe.contentWindow;
      expect(frameWindow, isWindow);
      //TODO(gram) The next test should be written as:
      //    expect(frameWindow, isNot(isLocalWindow));
      // but that will cause problems now until is/is! work
      // properly in dart2js instead of always returning true.
      expect(frameWindow is! LocalWindow, isTrue);
      expect(frameWindow.parent, isLocalWindow);

      // Ensure that the frame's document is inaccessible via window.
      expect(() => frameWindow.document, throws);
    });

  test('contentDocument', () {
      // Ensure that the frame's document is inaccessible.
      expect(() => iframe.contentDocument, throws);
    });

  test('location', () {
      expect(window.location, isLocalLocation);
      final frameLocation = iframe.contentWindow.location;
      expect(frameLocation, isLocation);
      // TODO(gram) Similar to the above, the next test should be:
      //     expect(frameLocation, isNot(isLocalLocation));
      expect(frameLocation is! LocalLocation, isTrue);

      expect(() => frameLocation.href, throws);
      expect(() => frameLocation.hash, throws);

      final frameParentLocation = iframe.contentWindow.parent.location;
      expect(frameParentLocation, isLocalLocation);
    });

  test('history', () {
      expect(window.history, isLocalHistory);
      final frameHistory = iframe.contentWindow.history;
      expect(frameHistory, isHistory);
      // See earlier comments.
      //expect(frameHistory, isNot(isLocalHistory));
      expect(frameHistory is! LocalHistory, isTrue);

      // Valid methods.
      frameHistory.forward();

      expect(() => frameHistory.length, throws);

      final frameParentHistory = iframe.contentWindow.parent.history;
      expect(frameParentHistory, isLocalHistory);
    });
}
