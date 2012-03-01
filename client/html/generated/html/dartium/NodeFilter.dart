
class _NodeFilterImpl extends _DOMTypeBase implements NodeFilter {
  _NodeFilterImpl._wrap(ptr) : super._wrap(ptr);

  int acceptNode(Node n) {
    return _wrap(_ptr.acceptNode(_unwrap(n)));
  }
}
