library DOMParserTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {

  useHtmlConfiguration();

  var isDOMParser = predicate((x) => x is DOMParser, 'is a DOMParser');

  test('constructorTest', () {
      var ctx = new DOMParser();
      expect(ctx, isNotNull);
      expect(ctx, isDOMParser);
  });
}
