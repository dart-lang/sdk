import 'dart:html';

import 'package:minitest/minitest.dart';

main() {
  var isCssRuleList =
      predicate((x) => x is List<CssRule>, 'is a List<CssRule>');

  test("ClientRectList test", () {
    var sheet = document.styleSheets[0] as CssStyleSheet;
    List<CssRule> rulesList = sheet.cssRules;
    expect(rulesList, isCssRuleList);
  });
}
