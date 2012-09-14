#library('WindowEqualityTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
  var obfuscated = null;

  test('notNull', () {
      Expect.isNotNull(window);
      Expect.isTrue(window != obfuscated);
    });
}
