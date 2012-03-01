
class _NodeIteratorImpl extends _DOMTypeBase implements NodeIterator {
  _NodeIteratorImpl._wrap(ptr) : super._wrap(ptr);

  bool get expandEntityReferences() => _wrap(_ptr.expandEntityReferences);

  NodeFilter get filter() => _wrap(_ptr.filter);

  bool get pointerBeforeReferenceNode() => _wrap(_ptr.pointerBeforeReferenceNode);

  Node get referenceNode() => _wrap(_ptr.referenceNode);

  Node get root() => _wrap(_ptr.root);

  int get whatToShow() => _wrap(_ptr.whatToShow);

  void detach() {
    _ptr.detach();
    return;
  }

  Node nextNode() {
    return _wrap(_ptr.nextNode());
  }

  Node previousNode() {
    return _wrap(_ptr.previousNode());
  }
}
