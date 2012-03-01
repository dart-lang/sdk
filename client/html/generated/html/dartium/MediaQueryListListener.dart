
class _MediaQueryListListenerImpl extends _DOMTypeBase implements MediaQueryListListener {
  _MediaQueryListListenerImpl._wrap(ptr) : super._wrap(ptr);

  void queryChanged(MediaQueryList list) {
    _ptr.queryChanged(_unwrap(list));
    return;
  }
}
