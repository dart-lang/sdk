#library('XSLTProcessorTest');
#import('../../../../lib/unittest/unittest_dom.dart');
#import('dart:dom');

main() {

  forLayoutTests();

  test('constructorTest', () {
      var processor = new XSLTProcessor();
      Expect.isTrue(processor != null);
      Expect.isTrue(processor is XSLTProcessor);
    });
}
