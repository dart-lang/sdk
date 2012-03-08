
class _MetadataImpl extends _DOMTypeBase implements Metadata {
  _MetadataImpl._wrap(ptr) : super._wrap(ptr);

  Date get modificationTime() => _wrap(_ptr.modificationTime);

  int get size() => _wrap(_ptr.size);
}
