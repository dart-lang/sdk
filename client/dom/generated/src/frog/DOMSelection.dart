
class DOMSelection native "DOMSelection" {

  Node anchorNode;

  int anchorOffset;

  Node baseNode;

  int baseOffset;

  Node extentNode;

  int extentOffset;

  Node focusNode;

  int focusOffset;

  bool isCollapsed;

  int rangeCount;

  String type;

  void addRange(Range range) native;

  void collapse(Node node, int index) native;

  void collapseToEnd() native;

  void collapseToStart() native;

  bool containsNode(Node node, bool allowPartial) native;

  void deleteFromDocument() native;

  void empty() native;

  void extend(Node node, int offset) native;

  Range getRangeAt(int index) native;

  void modify(String alter, String direction, String granularity) native;

  void removeAllRanges() native;

  void selectAllChildren(Node node) native;

  void setBaseAndExtent(Node baseNode, int baseOffset, Node extentNode, int extentOffset) native;

  void setPosition(Node node, int offset) native;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
