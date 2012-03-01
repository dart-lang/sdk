
class _TreeWalkerImpl implements TreeWalker native "*TreeWalker" {

  _NodeImpl currentNode;

  final bool expandEntityReferences;

  final _NodeFilterImpl filter;

  final _NodeImpl root;

  final int whatToShow;

  _NodeImpl firstChild() native;

  _NodeImpl lastChild() native;

  _NodeImpl nextNode() native;

  _NodeImpl nextSibling() native;

  _NodeImpl parentNode() native;

  _NodeImpl previousNode() native;

  _NodeImpl previousSibling() native;
}
