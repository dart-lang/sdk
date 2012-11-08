library WindowEqualityTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();
  var obfuscated = null;

  test('notNull', () {
      expect(window, isNotNull);
      expect(window, isNot(equals(obfuscated)));
    });
}
