library HistoryTest;

import 'package:async_helper/async_minitest.dart';
import 'dart:html';
import 'dart:async';

main() {
  test('supported', () {
    expect(HashChangeEvent.supported, true);
  });
}

