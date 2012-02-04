
class _TreeWalkerJs extends _DOMTypeJs implements TreeWalker native "*TreeWalker" {

  _NodeJs currentNode;

  final bool expandEntityReferences;

  final _NodeFilterJs filter;

  final _NodeJs root;

  final int whatToShow;

  _NodeJs firstChild() native;

  _NodeJs lastChild() native;

  _NodeJs nextNode() native;

  _NodeJs nextSibling() native;

  _NodeJs parentNode() native;

  _NodeJs previousNode() native;

  _NodeJs previousSibling() native;
}
