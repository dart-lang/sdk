
class _DOMSelectionImpl extends _DOMTypeBase implements DOMSelection {
  _DOMSelectionImpl._wrap(ptr) : super._wrap(ptr);

  Node get anchorNode() => _wrap(_ptr.anchorNode);

  int get anchorOffset() => _wrap(_ptr.anchorOffset);

  Node get baseNode() => _wrap(_ptr.baseNode);

  int get baseOffset() => _wrap(_ptr.baseOffset);

  Node get extentNode() => _wrap(_ptr.extentNode);

  int get extentOffset() => _wrap(_ptr.extentOffset);

  Node get focusNode() => _wrap(_ptr.focusNode);

  int get focusOffset() => _wrap(_ptr.focusOffset);

  bool get isCollapsed() => _wrap(_ptr.isCollapsed);

  int get rangeCount() => _wrap(_ptr.rangeCount);

  String get type() => _wrap(_ptr.type);

  void addRange(Range range) {
    _ptr.addRange(_unwrap(range));
    return;
  }

  void collapse(Node node, int index) {
    _ptr.collapse(_unwrap(node), _unwrap(index));
    return;
  }

  void collapseToEnd() {
    _ptr.collapseToEnd();
    return;
  }

  void collapseToStart() {
    _ptr.collapseToStart();
    return;
  }

  bool containsNode(Node node, bool allowPartial) {
    return _wrap(_ptr.containsNode(_unwrap(node), _unwrap(allowPartial)));
  }

  void deleteFromDocument() {
    _ptr.deleteFromDocument();
    return;
  }

  void empty() {
    _ptr.empty();
    return;
  }

  void extend(Node node, int offset) {
    _ptr.extend(_unwrap(node), _unwrap(offset));
    return;
  }

  Range getRangeAt(int index) {
    return _wrap(_ptr.getRangeAt(_unwrap(index)));
  }

  void modify(String alter, String direction, String granularity) {
    _ptr.modify(_unwrap(alter), _unwrap(direction), _unwrap(granularity));
    return;
  }

  void removeAllRanges() {
    _ptr.removeAllRanges();
    return;
  }

  void selectAllChildren(Node node) {
    _ptr.selectAllChildren(_unwrap(node));
    return;
  }

  void setBaseAndExtent(Node baseNode, int baseOffset, Node extentNode, int extentOffset) {
    _ptr.setBaseAndExtent(_unwrap(baseNode), _unwrap(baseOffset), _unwrap(extentNode), _unwrap(extentOffset));
    return;
  }

  void setPosition(Node node, int offset) {
    _ptr.setPosition(_unwrap(node), _unwrap(offset));
    return;
  }

  String toString() {
    return _wrap(_ptr.toString());
  }
}
