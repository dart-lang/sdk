
class _DOMSelectionJs extends _DOMTypeJs implements DOMSelection native "*DOMSelection" {

  final _NodeJs anchorNode;

  final int anchorOffset;

  final _NodeJs baseNode;

  final int baseOffset;

  final _NodeJs extentNode;

  final int extentOffset;

  final _NodeJs focusNode;

  final int focusOffset;

  final bool isCollapsed;

  final int rangeCount;

  final String type;

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
