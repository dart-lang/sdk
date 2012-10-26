#library('WindowEqualityTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
  var obfuscated = null;

  test('notNull', () {
      expect(window, isNotNull);
      expect(window, isNot(equals(obfuscated)));
    });
}
