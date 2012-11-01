library CSSRuleListTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {

  var isCSSRuleList =
      predicate((x) => x is List<CSSRule>, 'is a List<CSSRule>');

  useHtmlConfiguration();

  test("ClientRectList test", () {
    var sheet = document.styleSheets[0];
    List<CSSRule> rulesList = sheet.cssRules;
    expect(rulesList, isCSSRuleList);
  });
}
