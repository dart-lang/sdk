import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  test('supported', () {
    expect(NumberInputElement.supported, true);
  });
}
