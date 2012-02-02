
class _TreeWalkerJs extends _DOMTypeJs implements TreeWalker native "*TreeWalker" {

  _NodeJs get currentNode() native "return this.currentNode;";

  void set currentNode(_NodeJs value) native "this.currentNode = value;";

  bool get expandEntityReferences() native "return this.expandEntityReferences;";

  _NodeFilterJs get filter() native "return this.filter;";

  _NodeJs get root() native "return this.root;";

  int get whatToShow() native "return this.whatToShow;";

  _NodeJs firstChild() native;

  _NodeJs lastChild() native;

  _NodeJs nextNode() native;

  _NodeJs nextSibling() native;

  _NodeJs parentNode() native;

  _NodeJs previousNode() native;

  _NodeJs previousSibling() native;
}
