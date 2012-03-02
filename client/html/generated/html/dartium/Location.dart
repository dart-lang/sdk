
class _LocationImpl extends _DOMTypeBase implements Location {
  _LocationImpl._wrap(ptr) : super._wrap(ptr);

  String get hash() => _wrap(_ptr.hash);

  void set hash(String value) { _ptr.hash = _unwrap(value); }

  String get host() => _wrap(_ptr.host);

  void set host(String value) { _ptr.host = _unwrap(value); }

  String get hostname() => _wrap(_ptr.hostname);

  void set hostname(String value) { _ptr.hostname = _unwrap(value); }

  String get href() => _wrap(_ptr.href);

  void set href(String value) { _ptr.href = _unwrap(value); }

  String get origin() => _wrap(_ptr.origin);

  String get pathname() => _wrap(_ptr.pathname);

  void set pathname(String value) { _ptr.pathname = _unwrap(value); }

  String get port() => _wrap(_ptr.port);

  void set port(String value) { _ptr.port = _unwrap(value); }

  String get protocol() => _wrap(_ptr.protocol);

  void set protocol(String value) { _ptr.protocol = _unwrap(value); }

  String get search() => _wrap(_ptr.search);

  void set search(String value) { _ptr.search = _unwrap(value); }

  void assign(String url) {
    _ptr.assign(_unwrap(url));
    return;
  }

  void reload() {
    _ptr.reload();
    return;
  }

  void replace(String url) {
    _ptr.replace(_unwrap(url));
    return;
  }

  String toString() {
    return _wrap(_ptr.toString());
  }
}
