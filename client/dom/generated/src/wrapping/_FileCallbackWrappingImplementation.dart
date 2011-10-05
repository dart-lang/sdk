// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _FileCallbackWrappingImplementation extends DOMWrapperBase implements FileCallback {
  _FileCallbackWrappingImplementation() : super() {}

  static create__FileCallbackWrappingImplementation() native {
    return new _FileCallbackWrappingImplementation();
  }

  bool handleEvent(File file) {
    return _handleEvent(this, file);
  }
  static bool _handleEvent(receiver, file) native;

  String get typeName() { return "FileCallback"; }
}
