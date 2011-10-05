// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DirectoryEntrySyncWrappingImplementation extends _EntrySyncWrappingImplementation implements DirectoryEntrySync {
  _DirectoryEntrySyncWrappingImplementation() : super() {}

  static create__DirectoryEntrySyncWrappingImplementation() native {
    return new _DirectoryEntrySyncWrappingImplementation();
  }

  DirectoryReaderSync createReader() {
    return _createReader(this);
  }
  static DirectoryReaderSync _createReader(receiver) native;

  DirectoryEntrySync getDirectory(String path, WebKitFlags flags) {
    return _getDirectory(this, path, flags);
  }
  static DirectoryEntrySync _getDirectory(receiver, path, flags) native;

  FileEntrySync getFile(String path, WebKitFlags flags) {
    return _getFile(this, path, flags);
  }
  static FileEntrySync _getFile(receiver, path, flags) native;

  void removeRecursively() {
    _removeRecursively(this);
    return;
  }
  static void _removeRecursively(receiver) native;

  String get typeName() { return "DirectoryEntrySync"; }
}
