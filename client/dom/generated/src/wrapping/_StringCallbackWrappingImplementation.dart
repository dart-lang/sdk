// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _StringCallbackWrappingImplementation extends DOMWrapperBase implements StringCallback {
  _StringCallbackWrappingImplementation() : super() {}

  static create__StringCallbackWrappingImplementation() native {
    return new _StringCallbackWrappingImplementation();
  }

  bool handleEvent(String data) {
    return _handleEvent(this, data);
  }
  static bool _handleEvent(receiver, data) native;

  String get typeName() { return "StringCallback"; }
}
