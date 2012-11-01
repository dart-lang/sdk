library HistoryTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();
  test('History', () {
    window.history.pushState(null, document.title, '?foo=bar');
    expect(window.history.length, equals(2));
    window.history.back();
    expect(window.location.href.endsWith('foo=bar'), isTrue);

    window.history.replaceState(null, document.title, '?foo=baz');
    expect(window.history.length, equals(2));
    expect(window.location.href.endsWith('foo=baz'), isTrue);
  });
}
