
class RangeJs extends DOMTypeJs implements Range native "*Range" {

  static final int END_TO_END = 2;

  static final int END_TO_START = 3;

  static final int NODE_AFTER = 1;

  static final int NODE_BEFORE = 0;

  static final int NODE_BEFORE_AND_AFTER = 2;

  static final int NODE_INSIDE = 3;

  static final int START_TO_END = 1;

  static final int START_TO_START = 0;

  bool get collapsed() native "return this.collapsed;";

  NodeJs get commonAncestorContainer() native "return this.commonAncestorContainer;";

  NodeJs get endContainer() native "return this.endContainer;";

  int get endOffset() native "return this.endOffset;";

  NodeJs get startContainer() native "return this.startContainer;";

  int get startOffset() native "return this.startOffset;";

  DocumentFragmentJs cloneContents() native;

  RangeJs cloneRange() native;

  void collapse(bool toStart) native;

  int compareNode(NodeJs refNode) native;

  int comparePoint(NodeJs refNode, int offset) native;

  DocumentFragmentJs createContextualFragment(String html) native;

  void deleteContents() native;

  void detach() native;

  void expand(String unit) native;

  DocumentFragmentJs extractContents() native;

  ClientRectJs getBoundingClientRect() native;

  ClientRectListJs getClientRects() native;

  void insertNode(NodeJs newNode) native;

  bool intersectsNode(NodeJs refNode) native;

  bool isPointInRange(NodeJs refNode, int offset) native;

  void selectNode(NodeJs refNode) native;

  void selectNodeContents(NodeJs refNode) native;

  void setEnd(NodeJs refNode, int offset) native;

  void setEndAfter(NodeJs refNode) native;

  void setEndBefore(NodeJs refNode) native;

  void setStart(NodeJs refNode, int offset) native;

  void setStartAfter(NodeJs refNode) native;

  void setStartBefore(NodeJs refNode) native;

  void surroundContents(NodeJs newParent) native;

  String toString() native;
}
