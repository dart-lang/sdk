#library('WindowEqualityTest');
#import('../../../../lib/unittest/unittest.dart');
#import('../../../../lib/unittest/dom_config.dart');
#import('dart:dom');

main() {
  useDomConfiguration();
  var obfuscated = null;

  test('notNull', () {
      Expect.isNotNull(window);
      Expect.isTrue(window != obfuscated);
    });
}
