
class NodeSelector native "*NodeSelector" {

  Element querySelector(String selectors) native;

  NodeList querySelectorAll(String selectors) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
