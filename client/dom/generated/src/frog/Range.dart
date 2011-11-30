
class Range native "*Range" {

  static final int END_TO_END = 2;

  static final int END_TO_START = 3;

  static final int NODE_AFTER = 1;

  static final int NODE_BEFORE = 0;

  static final int NODE_BEFORE_AND_AFTER = 2;

  static final int NODE_INSIDE = 3;

  static final int START_TO_END = 1;

  static final int START_TO_START = 0;

  bool collapsed;

  Node commonAncestorContainer;

  Node endContainer;

  int endOffset;

  Node startContainer;

  int startOffset;

  DocumentFragment cloneContents() native;

  Range cloneRange() native;

  void collapse(bool toStart) native;

  int compareNode(Node refNode) native;

  int comparePoint(Node refNode, int offset) native;

  DocumentFragment createContextualFragment(String html) native;

  void deleteContents() native;

  void detach() native;

  void expand(String unit) native;

  DocumentFragment extractContents() native;

  ClientRect getBoundingClientRect() native;

  ClientRectList getClientRects() native;

  void insertNode(Node newNode) native;

  bool intersectsNode(Node refNode) native;

  bool isPointInRange(Node refNode, int offset) native;

  void selectNode(Node refNode) native;

  void selectNodeContents(Node refNode) native;

  void setEnd(Node refNode, int offset) native;

  void setEndAfter(Node refNode) native;

  void setEndBefore(Node refNode) native;

  void setStart(Node refNode, int offset) native;

  void setStartAfter(Node refNode) native;

  void setStartBefore(Node refNode) native;

  void surroundContents(Node newParent) native;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
