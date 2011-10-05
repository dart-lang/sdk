// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DirectoryEntrySyncWrappingImplementation extends EntrySyncWrappingImplementation implements DirectoryEntrySync {
  DirectoryEntrySyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  DirectoryReaderSync createReader() {
    return LevelDom.wrapDirectoryReaderSync(_ptr.createReader());
  }

  DirectoryEntrySync getDirectory(String path, Flags flags) {
    return LevelDom.wrapDirectoryEntrySync(_ptr.getDirectory(path, LevelDom.unwrap(flags)));
  }

  FileEntrySync getFile(String path, Flags flags) {
    return LevelDom.wrapFileEntrySync(_ptr.getFile(path, LevelDom.unwrap(flags)));
  }

  void removeRecursively() {
    _ptr.removeRecursively();
    return;
  }

  String get typeName() { return "DirectoryEntrySync"; }
}
