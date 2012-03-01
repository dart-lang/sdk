
class _AreaElementImpl extends _ElementImpl implements AreaElement {
  _AreaElementImpl._wrap(ptr) : super._wrap(ptr);

  String get alt() => _wrap(_ptr.alt);

  void set alt(String value) { _ptr.alt = _unwrap(value); }

  String get coords() => _wrap(_ptr.coords);

  void set coords(String value) { _ptr.coords = _unwrap(value); }

  String get hash() => _wrap(_ptr.hash);

  String get host() => _wrap(_ptr.host);

  String get hostname() => _wrap(_ptr.hostname);

  String get href() => _wrap(_ptr.href);

  void set href(String value) { _ptr.href = _unwrap(value); }

  bool get noHref() => _wrap(_ptr.noHref);

  void set noHref(bool value) { _ptr.noHref = _unwrap(value); }

  String get pathname() => _wrap(_ptr.pathname);

  String get ping() => _wrap(_ptr.ping);

  void set ping(String value) { _ptr.ping = _unwrap(value); }

  String get port() => _wrap(_ptr.port);

  String get protocol() => _wrap(_ptr.protocol);

  String get search() => _wrap(_ptr.search);

  String get shape() => _wrap(_ptr.shape);

  void set shape(String value) { _ptr.shape = _unwrap(value); }

  String get target() => _wrap(_ptr.target);

  void set target(String value) { _ptr.target = _unwrap(value); }
}
