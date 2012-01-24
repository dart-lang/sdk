
class DOMSelectionJs extends DOMTypeJs implements DOMSelection native "*DOMSelection" {

  NodeJs get anchorNode() native "return this.anchorNode;";

  int get anchorOffset() native "return this.anchorOffset;";

  NodeJs get baseNode() native "return this.baseNode;";

  int get baseOffset() native "return this.baseOffset;";

  NodeJs get extentNode() native "return this.extentNode;";

  int get extentOffset() native "return this.extentOffset;";

  NodeJs get focusNode() native "return this.focusNode;";

  int get focusOffset() native "return this.focusOffset;";

  bool get isCollapsed() native "return this.isCollapsed;";

  int get rangeCount() native "return this.rangeCount;";

  String get type() native "return this.type;";

  void addRange(RangeJs range) native;

  void collapse(NodeJs node, int index) native;

  void collapseToEnd() native;

  void collapseToStart() native;

  bool containsNode(NodeJs node, bool allowPartial) native;

  void deleteFromDocument() native;

  void empty() native;

  void extend(NodeJs node, int offset) native;

  RangeJs getRangeAt(int index) native;

  void modify(String alter, String direction, String granularity) native;

  void removeAllRanges() native;

  void selectAllChildren(NodeJs node) native;

  void setBaseAndExtent(NodeJs baseNode, int baseOffset, NodeJs extentNode, int extentOffset) native;

  void setPosition(NodeJs node, int offset) native;

  String toString() native;
}
