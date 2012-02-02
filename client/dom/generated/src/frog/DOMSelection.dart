
class _DOMSelectionJs extends _DOMTypeJs implements DOMSelection native "*DOMSelection" {

  _NodeJs get anchorNode() native "return this.anchorNode;";

  int get anchorOffset() native "return this.anchorOffset;";

  _NodeJs get baseNode() native "return this.baseNode;";

  int get baseOffset() native "return this.baseOffset;";

  _NodeJs get extentNode() native "return this.extentNode;";

  int get extentOffset() native "return this.extentOffset;";

  _NodeJs get focusNode() native "return this.focusNode;";

  int get focusOffset() native "return this.focusOffset;";

  bool get isCollapsed() native "return this.isCollapsed;";

  int get rangeCount() native "return this.rangeCount;";

  String get type() native "return this.type;";

  void addRange(_RangeJs range) native;

  void collapse(_NodeJs node, int index) native;

  void collapseToEnd() native;

  void collapseToStart() native;

  bool containsNode(_NodeJs node, bool allowPartial) native;

  void deleteFromDocument() native;

  void empty() native;

  void extend(_NodeJs node, int offset) native;

  _RangeJs getRangeAt(int index) native;

  void modify(String alter, String direction, String granularity) native;

  void removeAllRanges() native;

  void selectAllChildren(_NodeJs node) native;

  void setBaseAndExtent(_NodeJs baseNode, int baseOffset, _NodeJs extentNode, int extentOffset) native;

  void setPosition(_NodeJs node, int offset) native;

  String toString() native;
}
