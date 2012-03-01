
class _DOMFormDataImpl extends _DOMTypeBase implements DOMFormData {
  _DOMFormDataImpl._wrap(ptr) : super._wrap(ptr);

  void append(String name, String value, String filename) {
    _ptr.append(_unwrap(name), _unwrap(value), _unwrap(filename));
    return;
  }
}
