
class NodeIteratorJs extends DOMTypeJs implements NodeIterator native "*NodeIterator" {

  bool get expandEntityReferences() native "return this.expandEntityReferences;";

  NodeFilterJs get filter() native "return this.filter;";

  bool get pointerBeforeReferenceNode() native "return this.pointerBeforeReferenceNode;";

  NodeJs get referenceNode() native "return this.referenceNode;";

  NodeJs get root() native "return this.root;";

  int get whatToShow() native "return this.whatToShow;";

  void detach() native;

  NodeJs nextNode() native;

  NodeJs previousNode() native;
}
