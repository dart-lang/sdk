
class _WebGLActiveInfoImpl extends _DOMTypeBase implements WebGLActiveInfo {
  _WebGLActiveInfoImpl._wrap(ptr) : super._wrap(ptr);

  String get name() => _wrap(_ptr.name);

  int get size() => _wrap(_ptr.size);

  int get type() => _wrap(_ptr.type);
}
