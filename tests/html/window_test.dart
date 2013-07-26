library WindowTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  test('scrollXY', () {
    expect(window.scrollX, 0);
    expect(window.scrollY, 0);
  });
}
