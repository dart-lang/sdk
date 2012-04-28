#library('XSLTProcessorTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {

  useHtmlConfiguration();

  test('constructorTest', () {
      var processor = new XSLTProcessor();
      Expect.isTrue(processor != null);
      Expect.isTrue(processor is XSLTProcessor);
    });
}
