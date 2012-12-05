library XSLTProcessorTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {

  useHtmlConfiguration();

  var isXsltProcessor =
      predicate((x) => x is XsltProcessor, 'is an XsltProcessor');

  test('constructorTest', () {
      var processor = new XsltProcessor();
      expect(processor, isNotNull);
      expect(processor, isXsltProcessor);
    });
}
