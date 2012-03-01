
class _NotationImpl extends _NodeImpl implements Notation {
  _NotationImpl._wrap(ptr) : super._wrap(ptr);

  String get publicId() => _wrap(_ptr.publicId);

  String get systemId() => _wrap(_ptr.systemId);
}
