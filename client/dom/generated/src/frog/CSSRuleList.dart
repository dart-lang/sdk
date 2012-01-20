
class CSSRuleList native "*CSSRuleList" {

  int get length() native "return this.length;";

  CSSRule item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
