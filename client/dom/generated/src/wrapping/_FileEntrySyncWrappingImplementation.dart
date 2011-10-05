// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _FileEntrySyncWrappingImplementation extends _EntrySyncWrappingImplementation implements FileEntrySync {
  _FileEntrySyncWrappingImplementation() : super() {}

  static create__FileEntrySyncWrappingImplementation() native {
    return new _FileEntrySyncWrappingImplementation();
  }

  FileWriterSync createWriter() {
    return _createWriter(this);
  }
  static FileWriterSync _createWriter(receiver) native;

  File file() {
    return _file(this);
  }
  static File _file(receiver) native;

  String get typeName() { return "FileEntrySync"; }
}
