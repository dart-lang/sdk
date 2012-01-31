#library('ImplementationTest');
#import('../../../testing/unittest/unittest.dart');
#import('dart:dom');

main() {
  forLayoutTests();
  test('Dart', () {
    bool hasDart = document.implementation.hasFeature("dart", "");
    Expect.isTrue(hasDart);
  });
}
