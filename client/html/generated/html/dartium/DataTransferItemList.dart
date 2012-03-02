
class _DataTransferItemListImpl extends _DOMTypeBase implements DataTransferItemList {
  _DataTransferItemListImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  void add(var data_OR_file, [String type = null]) {
    if (data_OR_file is File) {
      if (type === null) {
        _ptr.add(_unwrap(data_OR_file));
        return;
      }
    } else {
      if (data_OR_file is String) {
        _ptr.add(_unwrap(data_OR_file), _unwrap(type));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void clear() {
    _ptr.clear();
    return;
  }

  DataTransferItem item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }
}
