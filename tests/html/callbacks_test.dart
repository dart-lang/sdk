library CallbacksTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();
  test('RequestAnimationFrameCallback', () {
    window.requestAnimationFrame((num time) => false);
  });
}
