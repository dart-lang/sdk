#library('XSLTProcessorTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom_deprecated');

main() {

  useDomConfiguration();

  test('constructorTest', () {
      var processor = new XSLTProcessor();
      Expect.isTrue(processor != null);
      Expect.isTrue(processor is XSLTProcessor);
    });
}
