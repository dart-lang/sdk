
class _WebKitNamedFlowImpl extends _DOMTypeBase implements WebKitNamedFlow {
  _WebKitNamedFlowImpl._wrap(ptr) : super._wrap(ptr);

  bool get overflow() => _wrap(_ptr.overflow);

  NodeList getRegionsByContentNode(Node contentNode) {
    return _wrap(_ptr.getRegionsByContentNode(_unwrap(contentNode)));
  }
}
