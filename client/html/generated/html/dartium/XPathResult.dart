
class _XPathResultImpl extends _DOMTypeBase implements XPathResult {
  _XPathResultImpl._wrap(ptr) : super._wrap(ptr);

  bool get booleanValue() => _wrap(_ptr.booleanValue);

  bool get invalidIteratorState() => _wrap(_ptr.invalidIteratorState);

  num get numberValue() => _wrap(_ptr.numberValue);

  int get resultType() => _wrap(_ptr.resultType);

  Node get singleNodeValue() => _wrap(_ptr.singleNodeValue);

  int get snapshotLength() => _wrap(_ptr.snapshotLength);

  String get stringValue() => _wrap(_ptr.stringValue);

  Node iterateNext() {
    return _wrap(_ptr.iterateNext());
  }

  Node snapshotItem(int index) {
    return _wrap(_ptr.snapshotItem(_unwrap(index)));
  }
}
