
class NodeIterator native "NodeIterator" {

  bool expandEntityReferences;

  NodeFilter filter;

  bool pointerBeforeReferenceNode;

  Node referenceNode;

  Node root;

  int whatToShow;

  void detach() native;

  Node nextNode() native;

  Node previousNode() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
