#library('CSSRuleListTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {

  useHtmlConfiguration();

  test("ClientRectList test", () {
    var sheet = document.styleSheets[0];
    List<CSSRule> rulesList = sheet.cssRules;
    Expect.isTrue(rulesList is List<CSSRule>);
  });
}
