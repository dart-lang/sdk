
class _DirectoryEntrySyncImpl extends _EntrySyncImpl implements DirectoryEntrySync {
  _DirectoryEntrySyncImpl._wrap(ptr) : super._wrap(ptr);

  DirectoryReaderSync createReader() {
    return _wrap(_ptr.createReader());
  }

  DirectoryEntrySync getDirectory(String path, Object flags) {
    return _wrap(_ptr.getDirectory(_unwrap(path), _unwrap(flags)));
  }

  FileEntrySync getFile(String path, Object flags) {
    return _wrap(_ptr.getFile(_unwrap(path), _unwrap(flags)));
  }

  void removeRecursively() {
    _ptr.removeRecursively();
    return;
  }
}
