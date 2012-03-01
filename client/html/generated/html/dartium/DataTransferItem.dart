
class _DataTransferItemImpl extends _DOMTypeBase implements DataTransferItem {
  _DataTransferItemImpl._wrap(ptr) : super._wrap(ptr);

  String get kind() => _wrap(_ptr.kind);

  String get type() => _wrap(_ptr.type);

  Blob getAsFile() {
    return _wrap(_ptr.getAsFile());
  }

  void getAsString(StringCallback callback) {
    _ptr.getAsString(_unwrap(callback));
    return;
  }
}
