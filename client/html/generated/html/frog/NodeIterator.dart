
class _NodeIteratorImpl implements NodeIterator native "*NodeIterator" {

  final bool expandEntityReferences;

  final _NodeFilterImpl filter;

  final bool pointerBeforeReferenceNode;

  final _NodeImpl referenceNode;

  final _NodeImpl root;

  final int whatToShow;

  void detach() native;

  _NodeImpl nextNode() native;

  _NodeImpl previousNode() native;
}
