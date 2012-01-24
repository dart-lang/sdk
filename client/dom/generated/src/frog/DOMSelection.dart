
class DOMSelectionJS implements DOMSelection native "*DOMSelection" {

  NodeJS get anchorNode() native "return this.anchorNode;";

  int get anchorOffset() native "return this.anchorOffset;";

  NodeJS get baseNode() native "return this.baseNode;";

  int get baseOffset() native "return this.baseOffset;";

  NodeJS get extentNode() native "return this.extentNode;";

  int get extentOffset() native "return this.extentOffset;";

  NodeJS get focusNode() native "return this.focusNode;";

  int get focusOffset() native "return this.focusOffset;";

  bool get isCollapsed() native "return this.isCollapsed;";

  int get rangeCount() native "return this.rangeCount;";

  String get type() native "return this.type;";

  void addRange(RangeJS range) native;

  void collapse(NodeJS node, int index) native;

  void collapseToEnd() native;

  void collapseToStart() native;

  bool containsNode(NodeJS node, bool allowPartial) native;

  void deleteFromDocument() native;

  void empty() native;

  void extend(NodeJS node, int offset) native;

  RangeJS getRangeAt(int index) native;

  void modify(String alter, String direction, String granularity) native;

  void removeAllRanges() native;

  void selectAllChildren(NodeJS node) native;

  void setBaseAndExtent(NodeJS baseNode, int baseOffset, NodeJS extentNode, int extentOffset) native;

  void setPosition(NodeJS node, int offset) native;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
