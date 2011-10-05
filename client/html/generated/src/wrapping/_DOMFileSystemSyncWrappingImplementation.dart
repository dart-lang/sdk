// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMFileSystemSyncWrappingImplementation extends DOMWrapperBase implements DOMFileSystemSync {
  DOMFileSystemSyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get name() { return _ptr.name; }

  DirectoryEntrySync get root() { return LevelDom.wrapDirectoryEntrySync(_ptr.root); }

  String get typeName() { return "DOMFileSystemSync"; }
}
