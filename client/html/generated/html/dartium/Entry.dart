
class _EntryImpl extends _DOMTypeBase implements Entry {
  _EntryImpl._wrap(ptr) : super._wrap(ptr);

  DOMFileSystem get filesystem() => _wrap(_ptr.filesystem);

  String get fullPath() => _wrap(_ptr.fullPath);

  bool get isDirectory() => _wrap(_ptr.isDirectory);

  bool get isFile() => _wrap(_ptr.isFile);

  String get name() => _wrap(_ptr.name);

  void copyTo(DirectoryEntry parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (name === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.copyTo(_unwrap(parent));
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.copyTo(_unwrap(parent), _unwrap(name));
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.copyTo(_unwrap(parent), _unwrap(name), _unwrap(successCallback));
          return;
        } else {
          _ptr.copyTo(_unwrap(parent), _unwrap(name), _unwrap(successCallback), _unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void getMetadata(MetadataCallback successCallback, [ErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.getMetadata(_unwrap(successCallback));
      return;
    } else {
      _ptr.getMetadata(_unwrap(successCallback), _unwrap(errorCallback));
      return;
    }
  }

  void getParent([EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.getParent();
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.getParent(_unwrap(successCallback));
        return;
      } else {
        _ptr.getParent(_unwrap(successCallback), _unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void moveTo(DirectoryEntry parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (name === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.moveTo(_unwrap(parent));
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.moveTo(_unwrap(parent), _unwrap(name));
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.moveTo(_unwrap(parent), _unwrap(name), _unwrap(successCallback));
          return;
        } else {
          _ptr.moveTo(_unwrap(parent), _unwrap(name), _unwrap(successCallback), _unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void remove(VoidCallback successCallback, [ErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.remove(_unwrap(successCallback));
      return;
    } else {
      _ptr.remove(_unwrap(successCallback), _unwrap(errorCallback));
      return;
    }
  }

  String toURL() {
    return _wrap(_ptr.toURL());
  }
}
