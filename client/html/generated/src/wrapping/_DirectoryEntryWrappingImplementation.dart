// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DirectoryEntryWrappingImplementation extends EntryWrappingImplementation implements DirectoryEntry {
  DirectoryEntryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  DirectoryReader createReader() {
    return LevelDom.wrapDirectoryReader(_ptr.createReader());
  }

  void getDirectory(String path, [Flags flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (flags === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getDirectory(path);
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getDirectory(path, LevelDom.unwrap(flags));
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.getDirectory(path, LevelDom.unwrap(flags), LevelDom.unwrap(successCallback));
          return;
        } else {
          _ptr.getDirectory(path, LevelDom.unwrap(flags), LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void getFile(String path, [Flags flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (flags === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getFile(path);
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getFile(path, LevelDom.unwrap(flags));
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.getFile(path, LevelDom.unwrap(flags), LevelDom.unwrap(successCallback));
          return;
        } else {
          _ptr.getFile(path, LevelDom.unwrap(flags), LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void removeRecursively([VoidCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.removeRecursively();
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.removeRecursively(LevelDom.unwrap(successCallback));
        return;
      } else {
        _ptr.removeRecursively(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
}
