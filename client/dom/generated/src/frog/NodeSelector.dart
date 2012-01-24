
class NodeSelectorJS implements NodeSelector native "*NodeSelector" {

  ElementJS querySelector(String selectors) native;

  NodeListJS querySelectorAll(String selectors) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
