
class CSSRuleListJS implements CSSRuleList native "*CSSRuleList" {

  int get length() native "return this.length;";

  CSSRuleJS item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
