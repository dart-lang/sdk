library HistoryTest;

import 'package:unittest/unittest.dart';
import 'dart:html';
import 'dart:async';

main() {
  test('supported', () {
    expect(HashChangeEvent.supported, true);
  });
}

