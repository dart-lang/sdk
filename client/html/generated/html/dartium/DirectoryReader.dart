
class _DirectoryReaderImpl extends _DOMTypeBase implements DirectoryReader {
  _DirectoryReaderImpl._wrap(ptr) : super._wrap(ptr);

  void readEntries(EntriesCallback successCallback, [ErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.readEntries(_unwrap(successCallback));
      return;
    } else {
      _ptr.readEntries(_unwrap(successCallback), _unwrap(errorCallback));
      return;
    }
  }
}
