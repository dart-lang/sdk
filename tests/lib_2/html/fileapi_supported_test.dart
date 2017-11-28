library fileapi;

import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';

main() {
  useHtmlIndividualConfiguration();

  test('supported', () {
    expect(FileSystem.supported, true);
  });

  test('requestFileSystem', () {
    var expectation = FileSystem.supported ? returnsNormally : throws;
    expect(() {
      window.requestFileSystem(100);
    }, expectation);
  });
}

