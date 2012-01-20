
class TreeWalker native "*TreeWalker" {

  Node get currentNode() native "return this.currentNode;";

  void set currentNode(Node value) native "this.currentNode = value;";

  bool get expandEntityReferences() native "return this.expandEntityReferences;";

  NodeFilter get filter() native "return this.filter;";

  Node get root() native "return this.root;";

  int get whatToShow() native "return this.whatToShow;";

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
