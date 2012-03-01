
class _RangeImpl implements Range native "*Range" {

  static final int END_TO_END = 2;

  static final int END_TO_START = 3;

  static final int NODE_AFTER = 1;

  static final int NODE_BEFORE = 0;

  static final int NODE_BEFORE_AND_AFTER = 2;

  static final int NODE_INSIDE = 3;

  static final int START_TO_END = 1;

  static final int START_TO_START = 0;

  final bool collapsed;

  final _NodeImpl commonAncestorContainer;

  final _NodeImpl endContainer;

  final int endOffset;

  final _NodeImpl startContainer;

  final int startOffset;

  _DocumentFragmentImpl cloneContents() native;

  _RangeImpl cloneRange() native;

  void collapse(bool toStart) native;

  int compareNode(_NodeImpl refNode) native;

  int comparePoint(_NodeImpl refNode, int offset) native;

  _DocumentFragmentImpl createContextualFragment(String html) native;

  void deleteContents() native;

  void detach() native;

  void expand(String unit) native;

  _DocumentFragmentImpl extractContents() native;

  _ClientRectImpl getBoundingClientRect() native;

  _ClientRectListImpl getClientRects() native;

  void insertNode(_NodeImpl newNode) native;

  bool intersectsNode(_NodeImpl refNode) native;

  bool isPointInRange(_NodeImpl refNode, int offset) native;

  void selectNode(_NodeImpl refNode) native;

  void selectNodeContents(_NodeImpl refNode) native;

  void setEnd(_NodeImpl refNode, int offset) native;

  void setEndAfter(_NodeImpl refNode) native;

  void setEndBefore(_NodeImpl refNode) native;

  void setStart(_NodeImpl refNode, int offset) native;

  void setStartAfter(_NodeImpl refNode) native;

  void setStartBefore(_NodeImpl refNode) native;

  void surroundContents(_NodeImpl newParent) native;

  String toString() native;
}
