
class _ClipboardImpl extends _DOMTypeBase implements Clipboard {
  _ClipboardImpl._wrap(ptr) : super._wrap(ptr);

  String get dropEffect() => _wrap(_ptr.dropEffect);

  void set dropEffect(String value) { _ptr.dropEffect = _unwrap(value); }

  String get effectAllowed() => _wrap(_ptr.effectAllowed);

  void set effectAllowed(String value) { _ptr.effectAllowed = _unwrap(value); }

  FileList get files() => _wrap(_ptr.files);

  DataTransferItemList get items() => _wrap(_ptr.items);

  List<String> get types() => _wrap(_ptr.types);

  void clearData([String type = null]) {
    if (type === null) {
      _ptr.clearData();
      return;
    } else {
      _ptr.clearData(_unwrap(type));
      return;
    }
  }

  void getData(String type) {
    _ptr.getData(_unwrap(type));
    return;
  }

  bool setData(String type, String data) {
    return _wrap(_ptr.setData(_unwrap(type), _unwrap(data)));
  }

  void setDragImage(ImageElement image, int x, int y) {
    _ptr.setDragImage(_unwrap(image), _unwrap(x), _unwrap(y));
    return;
  }
}
