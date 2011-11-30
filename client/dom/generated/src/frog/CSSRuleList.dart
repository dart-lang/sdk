
class CSSRuleList native "*CSSRuleList" {

  int length;

  CSSRule item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
