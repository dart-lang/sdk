library DOMParserTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  var isDomParser = predicate((x) => x is DomParser, 'is a DomParser');

  test('constructorTest', () {
    var ctx = new DomParser();
    expect(ctx, isNotNull);
    expect(ctx, isDomParser);
  });
}
