library HistoryTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';
import 'dart:async';

main() {
  useHtmlIndividualConfiguration();

  var expectation = History.supportsState ? returnsNormally : throws;

  test('pushState', () {
    expect(() {
      window.history.pushState(null, document.title, '?dummy');
      var length = window.history.length;

      window.history.pushState(null, document.title, '?foo=bar');

      expect(window.location.href.endsWith('foo=bar'), isTrue);
    }, expectation);
  });

  test('pushState with data', () {
    expect(() {
      window.history.pushState({'one': 1}, document.title, '?dummy');
      expect(window.history.state, equals({'one': 1}));
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
      new Timer(const Duration(milliseconds: 100), expectAsync(() {
        window.onPopState.first.then(expectAsync((_) {
          expect(window.history.length, length);
          expect(window.location.href.endsWith('dummy1'), isTrue);
        }));

        window.history.back();
      }));
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

  test('popstatevent', () {
    expect(() {
      var event = new Event.eventType('PopStateEvent', 'popstate');
      expect(event is PopStateEvent, true);
    }, expectation);
  });

  test('hashchangeevent', () {
    var expectation = HashChangeEvent.supported ? returnsNormally : throws;
    expect(() {
      var event = new HashChangeEvent('change', oldUrl: 'old', newUrl: 'new');
      expect(event is HashChangeEvent, true);
      expect(event.oldUrl, 'old');
      expect(event.newUrl, 'new');
    }, expectation);
  });
}

