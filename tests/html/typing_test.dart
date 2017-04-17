library TypingTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  var isStyleSheetList =
      predicate((x) => x is List<StyleSheet>, 'is a List<StyleSheet>');

  test('NodeList', () {
    List<Node> asList = window.document.queryAll('body');
    // Check it's Iterable
    int counter = 0;
    for (Node node in window.document.queryAll('body')) {
      counter++;
    }
    expect(counter, 1);
    counter = 0;
    window.document.queryAll('body').forEach((e) {
      counter++;
    });
    expect(counter, 1);
  });

  test('StyleSheetList', () {
    List<StyleSheet> asList = window.document.styleSheets;
    expect(asList, isStyleSheetList);
    // Check it's Iterable.
    int counter = 0;
    for (StyleSheet styleSheet in window.document.styleSheets) {
      counter++;
    }

    // There is one style sheet from the unittest framework.
    expect(counter, 1);
  });
}
