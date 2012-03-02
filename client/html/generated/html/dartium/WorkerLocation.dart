
class _WorkerLocationImpl extends _DOMTypeBase implements WorkerLocation {
  _WorkerLocationImpl._wrap(ptr) : super._wrap(ptr);

  String get hash() => _wrap(_ptr.hash);

  String get host() => _wrap(_ptr.host);

  String get hostname() => _wrap(_ptr.hostname);

  String get href() => _wrap(_ptr.href);

  String get pathname() => _wrap(_ptr.pathname);

  String get port() => _wrap(_ptr.port);

  String get protocol() => _wrap(_ptr.protocol);

  String get search() => _wrap(_ptr.search);

  String toString() {
    return _wrap(_ptr.toString());
  }
}
