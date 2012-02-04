
class _NodeIteratorJs extends _DOMTypeJs implements NodeIterator native "*NodeIterator" {

  final bool expandEntityReferences;

  final _NodeFilterJs filter;

  final bool pointerBeforeReferenceNode;

  final _NodeJs referenceNode;

  final _NodeJs root;

  final int whatToShow;

  void detach() native;

  _NodeJs nextNode() native;

  _NodeJs previousNode() native;
}
