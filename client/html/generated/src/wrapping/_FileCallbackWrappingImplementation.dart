// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileCallbackWrappingImplementation extends DOMWrapperBase implements FileCallback {
  FileCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool handleEvent(File file) {
    return _ptr.handleEvent(LevelDom.unwrap(file));
  }

  String get typeName() { return "FileCallback"; }
}
