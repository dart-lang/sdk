#library('BElementTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('create b', () {
    new Element.tag('b');
  });
}

