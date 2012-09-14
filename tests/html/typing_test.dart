#library('TypingTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('NodeList', () {
    List<Node> asList = window.document.queryAll('body');
    // Check it's Iterable
    int counter = 0;
    for (Node node in window.document.queryAll('body')) {
      counter++;
    }
    Expect.equals(1, counter);
    counter = 0;
    window.document.queryAll('body').forEach((e) { counter++; });
    Expect.equals(1, counter);
  });

  test('StyleSheetList', () {
    List<StyleSheet> asList = window.document.styleSheets;
    // Check it's Iterable.
    int counter = 0;
    for (StyleSheet styleSheet in window.document.styleSheets) {
      counter++;
    }

    // There is one style sheet from the unittest framework.
    Expect.equals(1, counter);
  });
}
