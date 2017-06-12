library NavigatorTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  test('language never returns null', () {
    expect(window.navigator.language, isNotNull);
  });
}
