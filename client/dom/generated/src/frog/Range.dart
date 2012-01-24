
class RangeJS implements Range native "*Range" {

  static final int END_TO_END = 2;

  static final int END_TO_START = 3;

  static final int NODE_AFTER = 1;

  static final int NODE_BEFORE = 0;

  static final int NODE_BEFORE_AND_AFTER = 2;

  static final int NODE_INSIDE = 3;

  static final int START_TO_END = 1;

  static final int START_TO_START = 0;

  bool get collapsed() native "return this.collapsed;";

  NodeJS get commonAncestorContainer() native "return this.commonAncestorContainer;";

  NodeJS get endContainer() native "return this.endContainer;";

  int get endOffset() native "return this.endOffset;";

  NodeJS get startContainer() native "return this.startContainer;";

  int get startOffset() native "return this.startOffset;";

  DocumentFragmentJS cloneContents() native;

  RangeJS cloneRange() native;

  void collapse(bool toStart) native;

  int compareNode(NodeJS refNode) native;

  int comparePoint(NodeJS refNode, int offset) native;

  DocumentFragmentJS createContextualFragment(String html) native;

  void deleteContents() native;

  void detach() native;

  void expand(String unit) native;

  DocumentFragmentJS extractContents() native;

  ClientRectJS getBoundingClientRect() native;

  ClientRectListJS getClientRects() native;

  void insertNode(NodeJS newNode) native;

  bool intersectsNode(NodeJS refNode) native;

  bool isPointInRange(NodeJS refNode, int offset) native;

  void selectNode(NodeJS refNode) native;

  void selectNodeContents(NodeJS refNode) native;

  void setEnd(NodeJS refNode, int offset) native;

  void setEndAfter(NodeJS refNode) native;

  void setEndBefore(NodeJS refNode) native;

  void setStart(NodeJS refNode, int offset) native;

  void setStartAfter(NodeJS refNode) native;

  void setStartBefore(NodeJS refNode) native;

  void surroundContents(NodeJS newParent) native;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
