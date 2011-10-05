// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DirectoryReaderSyncWrappingImplementation extends DOMWrapperBase implements DirectoryReaderSync {
  _DirectoryReaderSyncWrappingImplementation() : super() {}

  static create__DirectoryReaderSyncWrappingImplementation() native {
    return new _DirectoryReaderSyncWrappingImplementation();
  }

  EntryArraySync readEntries() {
    return _readEntries(this);
  }
  static EntryArraySync _readEntries(receiver) native;

  String get typeName() { return "DirectoryReaderSync"; }
}
