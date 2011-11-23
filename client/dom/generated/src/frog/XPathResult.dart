
class XPathResult native "*XPathResult" {

  bool booleanValue;

  bool invalidIteratorState;

  num numberValue;

  int resultType;

  Node singleNodeValue;

  int snapshotLength;

  String stringValue;

  Node iterateNext() native;

  Node snapshotItem(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
