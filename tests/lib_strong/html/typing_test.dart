import 'dart:html';

import 'package:expect/minitest.dart';

main() {
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
    window.document.queryAll('body').forEach((e) { counter++; });
    expect(counter, 1);
  });

  test('StyleSheetList', () {
    var document = window.document as HtmlDocument;
    List<StyleSheet> asList = document.styleSheets;
    expect(asList, isStyleSheetList);
    // Check it's Iterable.
    int counter = 0;
    for (StyleSheet styleSheet in document.styleSheets) {
      counter++;
    }

    // There are no style sheets.
    expect(counter, 0);
  });
}
