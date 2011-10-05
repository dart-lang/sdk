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

  void copyTo(DirectoryEntry parent, String name, EntryCallback successCallback, ErrorCallback errorCallback) {
    _ptr.copyTo(LevelDom.unwrap(parent), name, LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
    return;
  }

  void getMetadata(MetadataCallback successCallback, ErrorCallback errorCallback) {
    _ptr.getMetadata(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
    return;
  }

  void getParent(EntryCallback successCallback, ErrorCallback errorCallback) {
    _ptr.getParent(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
    return;
  }

  void moveTo(DirectoryEntry parent, String name, EntryCallback successCallback, ErrorCallback errorCallback) {
    _ptr.moveTo(LevelDom.unwrap(parent), name, LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
    return;
  }

  void remove(VoidCallback successCallback, ErrorCallback errorCallback) {
    _ptr.remove(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
    return;
  }

  String toURL() {
    return _ptr.toURL();
  }

  String get typeName() { return "Entry"; }
}
