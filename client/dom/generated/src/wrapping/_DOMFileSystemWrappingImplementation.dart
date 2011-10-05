// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMFileSystemWrappingImplementation extends DOMWrapperBase implements DOMFileSystem {
  _DOMFileSystemWrappingImplementation() : super() {}

  static create__DOMFileSystemWrappingImplementation() native {
    return new _DOMFileSystemWrappingImplementation();
  }

  String get name() { return _get__DOMFileSystem_name(this); }
  static String _get__DOMFileSystem_name(var _this) native;

  DirectoryEntry get root() { return _get__DOMFileSystem_root(this); }
  static DirectoryEntry _get__DOMFileSystem_root(var _this) native;

  String get typeName() { return "DOMFileSystem"; }
}
