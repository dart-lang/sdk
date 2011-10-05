// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _FileSystemCallbackWrappingImplementation extends DOMWrapperBase implements FileSystemCallback {
  _FileSystemCallbackWrappingImplementation() : super() {}

  static create__FileSystemCallbackWrappingImplementation() native {
    return new _FileSystemCallbackWrappingImplementation();
  }

  bool handleEvent(DOMFileSystem fileSystem) {
    return _handleEvent(this, fileSystem);
  }
  static bool _handleEvent(receiver, fileSystem) native;

  String get typeName() { return "FileSystemCallback"; }
}
