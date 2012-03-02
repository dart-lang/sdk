
class _CharacterDataImpl extends _NodeImpl implements CharacterData {
  _CharacterDataImpl._wrap(ptr) : super._wrap(ptr);

  String get data() => _wrap(_ptr.data);

  void set data(String value) { _ptr.data = _unwrap(value); }

  int get length() => _wrap(_ptr.length);

  void appendData(String data) {
    _ptr.appendData(_unwrap(data));
    return;
  }

  void deleteData(int offset, int length) {
    _ptr.deleteData(_unwrap(offset), _unwrap(length));
    return;
  }

  void insertData(int offset, String data) {
    _ptr.insertData(_unwrap(offset), _unwrap(data));
    return;
  }

  void replaceData(int offset, int length, String data) {
    _ptr.replaceData(_unwrap(offset), _unwrap(length), _unwrap(data));
    return;
  }

  String substringData(int offset, int length) {
    return _wrap(_ptr.substringData(_unwrap(offset), _unwrap(length)));
  }
}
