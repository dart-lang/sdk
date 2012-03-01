
class _DOMFileSystemSyncImpl extends _DOMTypeBase implements DOMFileSystemSync {
  _DOMFileSystemSyncImpl._wrap(ptr) : super._wrap(ptr);

  String get name() => _wrap(_ptr.name);

  DirectoryEntrySync get root() => _wrap(_ptr.root);
}
