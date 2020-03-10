library HistoryTest;

import 'package:unittest/unittest.dart';
import 'dart:html';
import 'dart:async';

main() {
  test('supports_state', () {
    expect(History.supportsState, true);
  });

  test('supported_HashChangeEvent', () {
    expect(HashChangeEvent.supported, true);
  });
}
