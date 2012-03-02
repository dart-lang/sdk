
class _DocumentFragmentImpl extends _NodeImpl implements DocumentFragment {
  _DocumentFragmentImpl._wrap(ptr) : super._wrap(ptr);

  Element query(String selectors) {
    return _wrap(_ptr.querySelector(_unwrap(selectors)));
  }

  NodeList queryAll(String selectors) {
    return _wrap(_ptr.querySelectorAll(_unwrap(selectors)));
  }
}
