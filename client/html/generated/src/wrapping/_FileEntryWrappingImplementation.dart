// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileEntryWrappingImplementation extends EntryWrappingImplementation implements FileEntry {
  FileEntryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void createWriter(FileWriterCallback successCallback, [ErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.createWriter(LevelDom.unwrap(successCallback));
      return;
    } else {
      _ptr.createWriter(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
      return;
    }
  }

  void file(FileCallback successCallback, [ErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.file(LevelDom.unwrap(successCallback));
      return;
    } else {
      _ptr.file(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
      return;
    }
  }
}
