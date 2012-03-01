
class _FileEntryImpl extends _EntryImpl implements FileEntry {
  _FileEntryImpl._wrap(ptr) : super._wrap(ptr);

  void createWriter(FileWriterCallback successCallback, [ErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.createWriter(_unwrap(successCallback));
      return;
    } else {
      _ptr.createWriter(_unwrap(successCallback), _unwrap(errorCallback));
      return;
    }
  }

  void file(FileCallback successCallback, [ErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.file(_unwrap(successCallback));
      return;
    } else {
      _ptr.file(_unwrap(successCallback), _unwrap(errorCallback));
      return;
    }
  }
}
