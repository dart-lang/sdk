library WindowEqualityTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();
  var obfuscated = null;

  test('notNull', () {
    expect(window, isNotNull);
    expect(window, isNot(equals(obfuscated)));
  });
}
