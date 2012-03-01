
class _TreeWalkerImpl extends _DOMTypeBase implements TreeWalker {
  _TreeWalkerImpl._wrap(ptr) : super._wrap(ptr);

  Node get currentNode() => _wrap(_ptr.currentNode);

  void set currentNode(Node value) { _ptr.currentNode = _unwrap(value); }

  bool get expandEntityReferences() => _wrap(_ptr.expandEntityReferences);

  NodeFilter get filter() => _wrap(_ptr.filter);

  Node get root() => _wrap(_ptr.root);

  int get whatToShow() => _wrap(_ptr.whatToShow);

  Node firstChild() {
    return _wrap(_ptr.firstChild());
  }

  Node lastChild() {
    return _wrap(_ptr.lastChild());
  }

  Node nextNode() {
    return _wrap(_ptr.nextNode());
  }

  Node nextSibling() {
    return _wrap(_ptr.nextSibling());
  }

  Node parentNode() {
    return _wrap(_ptr.parentNode());
  }

  Node previousNode() {
    return _wrap(_ptr.previousNode());
  }

  Node previousSibling() {
    return _wrap(_ptr.previousSibling());
  }
}
