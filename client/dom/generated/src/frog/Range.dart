
class _RangeJs extends _DOMTypeJs implements Range native "*Range" {

  static final int END_TO_END = 2;

  static final int END_TO_START = 3;

  static final int NODE_AFTER = 1;

  static final int NODE_BEFORE = 0;

  static final int NODE_BEFORE_AND_AFTER = 2;

  static final int NODE_INSIDE = 3;

  static final int START_TO_END = 1;

  static final int START_TO_START = 0;

  bool get collapsed() native "return this.collapsed;";

  _NodeJs get commonAncestorContainer() native "return this.commonAncestorContainer;";

  _NodeJs get endContainer() native "return this.endContainer;";

  int get endOffset() native "return this.endOffset;";

  _NodeJs get startContainer() native "return this.startContainer;";

  int get startOffset() native "return this.startOffset;";

  _DocumentFragmentJs cloneContents() native;

  _RangeJs cloneRange() native;

  void collapse(bool toStart) native;

  int compareNode(_NodeJs refNode) native;

  int comparePoint(_NodeJs refNode, int offset) native;

  _DocumentFragmentJs createContextualFragment(String html) native;

  void deleteContents() native;

  void detach() native;

  void expand(String unit) native;

  _DocumentFragmentJs extractContents() native;

  _ClientRectJs getBoundingClientRect() native;

  _ClientRectListJs getClientRects() native;

  void insertNode(_NodeJs newNode) native;

  bool intersectsNode(_NodeJs refNode) native;

  bool isPointInRange(_NodeJs refNode, int offset) native;

  void selectNode(_NodeJs refNode) native;

  void selectNodeContents(_NodeJs refNode) native;

  void setEnd(_NodeJs refNode, int offset) native;

  void setEndAfter(_NodeJs refNode) native;

  void setEndBefore(_NodeJs refNode) native;

  void setStart(_NodeJs refNode, int offset) native;

  void setStartAfter(_NodeJs refNode) native;

  void setStartBefore(_NodeJs refNode) native;

  void surroundContents(_NodeJs newParent) native;

  String toString() native;
}
