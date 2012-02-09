
class _XPathResultJs extends _DOMTypeJs implements XPathResult native "*XPathResult" {

  static final int ANY_TYPE = 0;

  static final int ANY_UNORDERED_NODE_TYPE = 8;

  static final int BOOLEAN_TYPE = 3;

  static final int FIRST_ORDERED_NODE_TYPE = 9;

  static final int NUMBER_TYPE = 1;

  static final int ORDERED_NODE_ITERATOR_TYPE = 5;

  static final int ORDERED_NODE_SNAPSHOT_TYPE = 7;

  static final int STRING_TYPE = 2;

  static final int UNORDERED_NODE_ITERATOR_TYPE = 4;

  static final int UNORDERED_NODE_SNAPSHOT_TYPE = 6;

  final bool booleanValue;

  final bool invalidIteratorState;

  final num numberValue;

  final int resultType;

  final _NodeJs singleNodeValue;

  final int snapshotLength;

  final String stringValue;

  _NodeJs iterateNext() native;

  _NodeJs snapshotItem(int index) native;
}
