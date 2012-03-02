
class _DOMFileSystemImpl extends _DOMTypeBase implements DOMFileSystem {
  _DOMFileSystemImpl._wrap(ptr) : super._wrap(ptr);

  String get name() => _wrap(_ptr.name);

  DirectoryEntry get root() => _wrap(_ptr.root);
}
