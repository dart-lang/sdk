library HistoryTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';

/// Waits for a callback once, then removes the event handler.
void expectAsync1Once(EventListenerList list, void callback(arg)) {
  var fn = null;
  fn = expectAsync1((arg) {
    list.remove(fn);
    callback(arg);
  });
  list.add(fn);
}

main() {
  useHtmlIndividualConfiguration();

  group('supported_state', () {
    test('supportsState', () {
      expect(History.supportsState, true);
    });
  });

  var expectation = History.supportsState ? returnsNormally : throws;

  group('history', () {
    test('pushState', () {
      expect(() {
        window.history.pushState(null, document.title, '?dummy');
        var length = window.history.length;

        window.history.pushState(null, document.title, '?foo=bar');

        expect(window.location.href.endsWith('foo=bar'), isTrue);

      }, expectation);
    });

    test('back', () {
      expect(() {
        window.history.pushState(null, document.title, '?dummy1');
        window.history.pushState(null, document.title, '?dummy2');
        var length = window.history.length;

        expect(window.location.href.endsWith('dummy2'), isTrue);

        // Need to wait a frame or two to let the pushState events occur.
        window.setTimeout(expectAsync0(() {
          expectAsync1Once(window.on.popState, (_) {
            expect(window.history.length, length);
            expect(window.location.href.endsWith('dummy1'), isTrue);
          });

          window.history.back();
        }), 100);
      }, expectation);
    });

    test('replaceState', () {
      expect(() {
        var length = window.history.length;

        window.history.replaceState(null, document.title, '?foo=baz');
        expect(window.history.length, length);
        expect(window.location.href.endsWith('foo=baz'), isTrue);
      }, expectation);
    });
  });
}
