#library('WindowEqualityTest');
#import('../../../testing/unittest/unittest_dom.dart');
#import('dart:dom');

main() {
  var obfuscated = null;

  test('notNull', () {
      Expect.isNotNull(window);
      Expect.isTrue(window != obfuscated);
    });
}
