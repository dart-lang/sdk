
class XPathResultJs extends DOMTypeJs implements XPathResult native "*XPathResult" {

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

  bool get booleanValue() native "return this.booleanValue;";

  bool get invalidIteratorState() native "return this.invalidIteratorState;";

  num get numberValue() native "return this.numberValue;";

  int get resultType() native "return this.resultType;";

  NodeJs get singleNodeValue() native "return this.singleNodeValue;";

  int get snapshotLength() native "return this.snapshotLength;";

  String get stringValue() native "return this.stringValue;";

  NodeJs iterateNext() native;

  NodeJs snapshotItem(int index) native;
}
