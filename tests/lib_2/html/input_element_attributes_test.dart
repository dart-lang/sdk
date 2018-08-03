import 'dart:html';

import 'package:expect/minitest.dart';

dynamic _undefined = (() => new List(5)[0])();

main() {
  test('valueSetNull', () {
    final e = new TextInputElement();
    e.value = null;
    expect(e.value, '');
  });
  test('valueSetNullProxy', () {
    final e = new TextInputElement();
    e.value = _undefined;
    expect(e.value, '');
  });
}
