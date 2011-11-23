
class MutationRecord native "*MutationRecord" {

  NodeList addedNodes;

  String attributeName;

  String attributeNamespace;

  Node nextSibling;

  String oldValue;

  Node previousSibling;

  NodeList removedNodes;

  Node target;

  String type;

  var dartObjectLocalStorage;

  String get typeName() native;
}
