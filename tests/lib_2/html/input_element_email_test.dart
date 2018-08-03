import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  test('supported', () {
    expect(EmailInputElement.supported, true);
  });
}

