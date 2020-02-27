library HistoryTest;

import 'package:unittest/unittest.dart';
import 'dart:html';
import 'dart:async';

main() {
  test('supportsState', () {
    expect(History.supportsState, true);
  });
}

