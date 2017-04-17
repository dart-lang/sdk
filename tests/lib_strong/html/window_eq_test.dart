import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  var obfuscated = null;

  test('notNull', () {
    expect(window, isNotNull);
    expect(window != obfuscated, isTrue);
  });
}
