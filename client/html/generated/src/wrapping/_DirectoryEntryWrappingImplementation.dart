// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DirectoryEntryWrappingImplementation extends EntryWrappingImplementation implements DirectoryEntry {
  DirectoryEntryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  DirectoryReader createReader() {
    return LevelDom.wrapDirectoryReader(_ptr.createReader());
  }

  void getDirectory(String path, Flags flags, EntryCallback successCallback, ErrorCallback errorCallback) {
    _ptr.getDirectory(path, LevelDom.unwrap(flags), LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
    return;
  }

  void getFile(String path, Flags flags, EntryCallback successCallback, ErrorCallback errorCallback) {
    _ptr.getFile(path, LevelDom.unwrap(flags), LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
    return;
  }

  void removeRecursively(VoidCallback successCallback, ErrorCallback errorCallback) {
    _ptr.removeRecursively(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
    return;
  }

  String get typeName() { return "DirectoryEntry"; }
}
