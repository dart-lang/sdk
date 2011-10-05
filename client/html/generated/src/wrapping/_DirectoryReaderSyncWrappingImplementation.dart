// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DirectoryReaderSyncWrappingImplementation extends DOMWrapperBase implements DirectoryReaderSync {
  DirectoryReaderSyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  EntryArraySync readEntries() {
    return LevelDom.wrapEntryArraySync(_ptr.readEntries());
  }

  String get typeName() { return "DirectoryReaderSync"; }
}
