
class _DOMSelectionImpl implements DOMSelection native "*DOMSelection" {

  final _NodeImpl anchorNode;

  final int anchorOffset;

  final _NodeImpl baseNode;

  final int baseOffset;

  final _NodeImpl extentNode;

  final int extentOffset;

  final _NodeImpl focusNode;

  final int focusOffset;

  final bool isCollapsed;

  final int rangeCount;

  final String type;

  void addRange(_RangeImpl range) native;

  void collapse(_NodeImpl node, int index) native;

  void collapseToEnd() native;

  void collapseToStart() native;

  bool containsNode(_NodeImpl node, bool allowPartial) native;

  void deleteFromDocument() native;

  void empty() native;

  void extend(_NodeImpl node, int offset) native;

  _RangeImpl getRangeAt(int index) native;

  void modify(String alter, String direction, String granularity) native;

  void removeAllRanges() native;

  void selectAllChildren(_NodeImpl node) native;

  void setBaseAndExtent(_NodeImpl baseNode, int baseOffset, _NodeImpl extentNode, int extentOffset) native;

  void setPosition(_NodeImpl node, int offset) native;

  String toString() native;
}
