
class TreeWalker native "TreeWalker" {

  Node currentNode;

  bool expandEntityReferences;

  NodeFilter filter;

  Node root;

  int whatToShow;

  Node firstChild() native;

  Node lastChild() native;

  Node nextNode() native;

  Node nextSibling() native;

  Node parentNode() native;

  Node previousNode() native;

  Node previousSibling() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
