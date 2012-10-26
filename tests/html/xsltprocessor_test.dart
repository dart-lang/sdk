#library('XSLTProcessorTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {

  useHtmlConfiguration();

  var isXSLTProcessor =
      predicate((x) => x is XSLTProcessor, 'is an XSLTProcessor');

  test('constructorTest', () {
      var processor = new XSLTProcessor();
      expect(processor, isNotNull);
      expect(processor, isXSLTProcessor);
    });
}
