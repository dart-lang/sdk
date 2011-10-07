// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMFileSystemWrappingImplementation extends DOMWrapperBase implements DOMFileSystem {
  DOMFileSystemWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get name() { return _ptr.name; }

  DirectoryEntry get root() { return LevelDom.wrapDirectoryEntry(_ptr.root); }
}
