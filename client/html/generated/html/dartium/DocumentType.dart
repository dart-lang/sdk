
class _DocumentTypeImpl extends _NodeImpl implements DocumentType {
  _DocumentTypeImpl._wrap(ptr) : super._wrap(ptr);

  NamedNodeMap get entities() => _wrap(_ptr.entities);

  String get internalSubset() => _wrap(_ptr.internalSubset);

  String get name() => _wrap(_ptr.name);

  NamedNodeMap get notations() => _wrap(_ptr.notations);

  String get publicId() => _wrap(_ptr.publicId);

  String get systemId() => _wrap(_ptr.systemId);
}
