
class _ScriptElementImpl extends _ElementImpl implements ScriptElement {
  _ScriptElementImpl._wrap(ptr) : super._wrap(ptr);

  bool get async() => _wrap(_ptr.async);

  void set async(bool value) { _ptr.async = _unwrap(value); }

  String get charset() => _wrap(_ptr.charset);

  void set charset(String value) { _ptr.charset = _unwrap(value); }

  bool get defer() => _wrap(_ptr.defer);

  void set defer(bool value) { _ptr.defer = _unwrap(value); }

  String get event() => _wrap(_ptr.event);

  void set event(String value) { _ptr.event = _unwrap(value); }

  String get htmlFor() => _wrap(_ptr.htmlFor);

  void set htmlFor(String value) { _ptr.htmlFor = _unwrap(value); }

  String get src() => _wrap(_ptr.src);

  void set src(String value) { _ptr.src = _unwrap(value); }

  String get type() => _wrap(_ptr.type);

  void set type(String value) { _ptr.type = _unwrap(value); }
}
