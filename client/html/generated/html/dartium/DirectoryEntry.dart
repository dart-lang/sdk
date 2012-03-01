
class _DirectoryEntryImpl extends _EntryImpl implements DirectoryEntry {
  _DirectoryEntryImpl._wrap(ptr) : super._wrap(ptr);

  DirectoryReader createReader() {
    return _wrap(_ptr.createReader());
  }

  void getDirectory(String path, [Object flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (flags === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getDirectory(_unwrap(path));
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getDirectory(_unwrap(path), _unwrap(flags));
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.getDirectory(_unwrap(path), _unwrap(flags), _unwrap(successCallback));
          return;
        } else {
          _ptr.getDirectory(_unwrap(path), _unwrap(flags), _unwrap(successCallback), _unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void getFile(String path, [Object flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (flags === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getFile(_unwrap(path));
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getFile(_unwrap(path), _unwrap(flags));
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.getFile(_unwrap(path), _unwrap(flags), _unwrap(successCallback));
          return;
        } else {
          _ptr.getFile(_unwrap(path), _unwrap(flags), _unwrap(successCallback), _unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void removeRecursively(VoidCallback successCallback, [ErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.removeRecursively(_unwrap(successCallback));
      return;
    } else {
      _ptr.removeRecursively(_unwrap(successCallback), _unwrap(errorCallback));
      return;
    }
  }
}
