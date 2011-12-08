// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntryWrappingImplementation extends DOMWrapperBase implements Entry {
  EntryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  DOMFileSystem get filesystem() { return LevelDom.wrapDOMFileSystem(_ptr.filesystem); }

  String get fullPath() { return _ptr.fullPath; }

  bool get isDirectory() { return _ptr.isDirectory; }

  bool get isFile() { return _ptr.isFile; }

  String get name() { return _ptr.name; }

  void copyTo(DirectoryEntry parent, [String name, EntryCallback successCallback, ErrorCallback errorCallback]) {
    if (name === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.copyTo(LevelDom.unwrap(parent));
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.copyTo(LevelDom.unwrap(parent), name);
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.copyTo(LevelDom.unwrap(parent), name, successCallback);
          return;
        } else {
          _ptr.copyTo(LevelDom.unwrap(parent), name, successCallback, LevelDom.unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void getMetadata([MetadataCallback successCallback, ErrorCallback errorCallback]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.getMetadata();
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.getMetadata(successCallback);
        return;
      } else {
        _ptr.getMetadata(successCallback, LevelDom.unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void getParent([EntryCallback successCallback, ErrorCallback errorCallback]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.getParent();
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.getParent(successCallback);
        return;
      } else {
        _ptr.getParent(successCallback, LevelDom.unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void moveTo(DirectoryEntry parent, [String name, EntryCallback successCallback, ErrorCallback errorCallback]) {
    if (name === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.moveTo(LevelDom.unwrap(parent));
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.moveTo(LevelDom.unwrap(parent), name);
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.moveTo(LevelDom.unwrap(parent), name, successCallback);
          return;
        } else {
          _ptr.moveTo(LevelDom.unwrap(parent), name, successCallback, LevelDom.unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void remove([VoidCallback successCallback, ErrorCallback errorCallback]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.remove();
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.remove(LevelDom.unwrap(successCallback));
        return;
      } else {
        _ptr.remove(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  String toURL() {
    return _ptr.toURL();
  }
}
