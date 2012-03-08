
class _DocumentFragmentImpl extends _NodeImpl implements DocumentFragment {
  _DocumentFragmentImpl._wrap(ptr) : super._wrap(ptr);

  ElementEvents get on() {
    if (_on == null) _on = new ElementEvents(this);
    return _on;
  }

  Element query(String selectors) {
    return _wrap(_ptr.querySelector(_unwrap(selectors)));
  }

  NodeList _querySelectorAll(String selectors) {
    return _wrap(_ptr.querySelectorAll(_unwrap(selectors)));
  }
}
