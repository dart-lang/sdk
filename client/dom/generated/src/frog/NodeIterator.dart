
class _NodeIteratorJs extends _DOMTypeJs implements NodeIterator native "*NodeIterator" {

  bool get expandEntityReferences() native "return this.expandEntityReferences;";

  _NodeFilterJs get filter() native "return this.filter;";

  bool get pointerBeforeReferenceNode() native "return this.pointerBeforeReferenceNode;";

  _NodeJs get referenceNode() native "return this.referenceNode;";

  _NodeJs get root() native "return this.root;";

  int get whatToShow() native "return this.whatToShow;";

  void detach() native;

  _NodeJs nextNode() native;

  _NodeJs previousNode() native;
}
