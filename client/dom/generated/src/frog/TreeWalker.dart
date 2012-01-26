
class TreeWalkerJs extends DOMTypeJs implements TreeWalker native "*TreeWalker" {

  NodeJs get currentNode() native "return this.currentNode;";

  void set currentNode(NodeJs value) native "this.currentNode = value;";

  bool get expandEntityReferences() native "return this.expandEntityReferences;";

  NodeFilterJs get filter() native "return this.filter;";

  NodeJs get root() native "return this.root;";

  int get whatToShow() native "return this.whatToShow;";

  NodeJs firstChild() native;

  NodeJs lastChild() native;

  NodeJs nextNode() native;

  NodeJs nextSibling() native;

  NodeJs parentNode() native;

  NodeJs previousNode() native;

  NodeJs previousSibling() native;
}
