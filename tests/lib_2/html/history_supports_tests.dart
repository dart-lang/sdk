library HistoryTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';
import 'dart:async';

main() {
  useHtmlIndividualConfiguration();

  test('supportsState', () {
    expect(History.supportsState, true);
  });
}

