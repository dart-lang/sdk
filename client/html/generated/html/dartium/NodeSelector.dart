
class _NodeSelectorImpl extends _DOMTypeBase implements NodeSelector {
  _NodeSelectorImpl._wrap(ptr) : super._wrap(ptr);

  Element query(String selectors) {
    return _wrap(_ptr.querySelector(_unwrap(selectors)));
  }

  NodeList _querySelectorAll(String selectors) {
    return _wrap(_ptr.querySelectorAll(_unwrap(selectors)));
  }
}
