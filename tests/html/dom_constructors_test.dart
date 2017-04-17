library DOMConstructorsTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();
  test('FileReader', () {
    FileReader fileReader = new FileReader();
    expect(fileReader.readyState, equals(FileReader.EMPTY));
  });
}
