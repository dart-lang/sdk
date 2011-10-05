// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntrySyncWrappingImplementation extends DOMWrapperBase implements EntrySync {
  EntrySyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  DOMFileSystemSync get filesystem() { return LevelDom.wrapDOMFileSystemSync(_ptr.filesystem); }

  String get fullPath() { return _ptr.fullPath; }

  bool get isDirectory() { return _ptr.isDirectory; }

  bool get isFile() { return _ptr.isFile; }

  String get name() { return _ptr.name; }

  EntrySync copyTo(DirectoryEntrySync parent, String name) {
    return LevelDom.wrapEntrySync(_ptr.copyTo(LevelDom.unwrap(parent), name));
  }

  Metadata getMetadata() {
    return LevelDom.wrapMetadata(_ptr.getMetadata());
  }

  DirectoryEntrySync getParent() {
    return LevelDom.wrapDirectoryEntrySync(_ptr.getParent());
  }

  EntrySync moveTo(DirectoryEntrySync parent, String name) {
    return LevelDom.wrapEntrySync(_ptr.moveTo(LevelDom.unwrap(parent), name));
  }

  void remove() {
    _ptr.remove();
    return;
  }

  String toURL() {
    return _ptr.toURL();
  }

  String get typeName() { return "EntrySync"; }
}
