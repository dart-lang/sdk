
class _RangeImpl extends _DOMTypeBase implements Range {
  _RangeImpl._wrap(ptr) : super._wrap(ptr);

  bool get collapsed() => _wrap(_ptr.collapsed);

  Node get commonAncestorContainer() => _wrap(_ptr.commonAncestorContainer);

  Node get endContainer() => _wrap(_ptr.endContainer);

  int get endOffset() => _wrap(_ptr.endOffset);

  Node get startContainer() => _wrap(_ptr.startContainer);

  int get startOffset() => _wrap(_ptr.startOffset);

  DocumentFragment cloneContents() {
    return _wrap(_ptr.cloneContents());
  }

  Range cloneRange() {
    return _wrap(_ptr.cloneRange());
  }

  void collapse(bool toStart) {
    _ptr.collapse(_unwrap(toStart));
    return;
  }

  int compareNode(Node refNode) {
    return _wrap(_ptr.compareNode(_unwrap(refNode)));
  }

  int comparePoint(Node refNode, int offset) {
    return _wrap(_ptr.comparePoint(_unwrap(refNode), _unwrap(offset)));
  }

  DocumentFragment createContextualFragment(String html) {
    return _wrap(_ptr.createContextualFragment(_unwrap(html)));
  }

  void deleteContents() {
    _ptr.deleteContents();
    return;
  }

  void detach() {
    _ptr.detach();
    return;
  }

  void expand(String unit) {
    _ptr.expand(_unwrap(unit));
    return;
  }

  DocumentFragment extractContents() {
    return _wrap(_ptr.extractContents());
  }

  ClientRect getBoundingClientRect() {
    return _wrap(_ptr.getBoundingClientRect());
  }

  ClientRectList getClientRects() {
    return _wrap(_ptr.getClientRects());
  }

  void insertNode(Node newNode) {
    _ptr.insertNode(_unwrap(newNode));
    return;
  }

  bool intersectsNode(Node refNode) {
    return _wrap(_ptr.intersectsNode(_unwrap(refNode)));
  }

  bool isPointInRange(Node refNode, int offset) {
    return _wrap(_ptr.isPointInRange(_unwrap(refNode), _unwrap(offset)));
  }

  void selectNode(Node refNode) {
    _ptr.selectNode(_unwrap(refNode));
    return;
  }

  void selectNodeContents(Node refNode) {
    _ptr.selectNodeContents(_unwrap(refNode));
    return;
  }

  void setEnd(Node refNode, int offset) {
    _ptr.setEnd(_unwrap(refNode), _unwrap(offset));
    return;
  }

  void setEndAfter(Node refNode) {
    _ptr.setEndAfter(_unwrap(refNode));
    return;
  }

  void setEndBefore(Node refNode) {
    _ptr.setEndBefore(_unwrap(refNode));
    return;
  }

  void setStart(Node refNode, int offset) {
    _ptr.setStart(_unwrap(refNode), _unwrap(offset));
    return;
  }

  void setStartAfter(Node refNode) {
    _ptr.setStartAfter(_unwrap(refNode));
    return;
  }

  void setStartBefore(Node refNode) {
    _ptr.setStartBefore(_unwrap(refNode));
    return;
  }

  void surroundContents(Node newParent) {
    _ptr.surroundContents(_unwrap(newParent));
    return;
  }

  String toString() {
    return _wrap(_ptr.toString());
  }
}
