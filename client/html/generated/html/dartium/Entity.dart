
class _EntityImpl extends _NodeImpl implements Entity {
  _EntityImpl._wrap(ptr) : super._wrap(ptr);

  String get notationName() => _wrap(_ptr.notationName);

  String get publicId() => _wrap(_ptr.publicId);

  String get systemId() => _wrap(_ptr.systemId);
}
