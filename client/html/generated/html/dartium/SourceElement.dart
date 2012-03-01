
class _SourceElementImpl extends _ElementImpl implements SourceElement {
  _SourceElementImpl._wrap(ptr) : super._wrap(ptr);

  String get media() => _wrap(_ptr.media);

  void set media(String value) { _ptr.media = _unwrap(value); }

  String get src() => _wrap(_ptr.src);

  void set src(String value) { _ptr.src = _unwrap(value); }

  String get type() => _wrap(_ptr.type);

  void set type(String value) { _ptr.type = _unwrap(value); }
}
