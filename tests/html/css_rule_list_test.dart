library CssRuleListTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {

  var isCssRuleList =
      predicate((x) => x is List<CssRule>, 'is a List<CssRule>');

  useHtmlConfiguration();

  test("ClientRectList test", () {
    var sheet = document.styleSheets[0];
    List<CssRule> rulesList = sheet.cssRules;
    expect(rulesList, isCssRuleList);
  });
}
