
class DOMSelection native "*DOMSelection" {

  Node get anchorNode() native "return this.anchorNode;";

  int get anchorOffset() native "return this.anchorOffset;";

  Node get baseNode() native "return this.baseNode;";

  int get baseOffset() native "return this.baseOffset;";

  Node get extentNode() native "return this.extentNode;";

  int get extentOffset() native "return this.extentOffset;";

  Node get focusNode() native "return this.focusNode;";

  int get focusOffset() native "return this.focusOffset;";

  bool get isCollapsed() native "return this.isCollapsed;";

  int get rangeCount() native "return this.rangeCount;";

  String get type() native "return this.type;";

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
