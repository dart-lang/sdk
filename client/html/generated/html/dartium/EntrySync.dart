
class _EntrySyncImpl extends _DOMTypeBase implements EntrySync {
  _EntrySyncImpl._wrap(ptr) : super._wrap(ptr);

  DOMFileSystemSync get filesystem() => _wrap(_ptr.filesystem);

  String get fullPath() => _wrap(_ptr.fullPath);

  bool get isDirectory() => _wrap(_ptr.isDirectory);

  bool get isFile() => _wrap(_ptr.isFile);

  String get name() => _wrap(_ptr.name);

  EntrySync copyTo(DirectoryEntrySync parent, String name) {
    return _wrap(_ptr.copyTo(_unwrap(parent), _unwrap(name)));
  }

  Metadata getMetadata() {
    return _wrap(_ptr.getMetadata());
  }

  DirectoryEntrySync getParent() {
    return _wrap(_ptr.getParent());
  }

  EntrySync moveTo(DirectoryEntrySync parent, String name) {
    return _wrap(_ptr.moveTo(_unwrap(parent), _unwrap(name)));
  }

  void remove() {
    _ptr.remove();
    return;
  }

  String toURL() {
    return _wrap(_ptr.toURL());
  }
}
