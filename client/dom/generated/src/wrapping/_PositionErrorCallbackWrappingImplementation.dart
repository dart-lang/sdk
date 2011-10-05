// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _PositionErrorCallbackWrappingImplementation extends DOMWrapperBase implements PositionErrorCallback {
  _PositionErrorCallbackWrappingImplementation() : super() {}

  static create__PositionErrorCallbackWrappingImplementation() native {
    return new _PositionErrorCallbackWrappingImplementation();
  }

  bool handleEvent(PositionError error) {
    return _handleEvent(this, error);
  }
  static bool _handleEvent(receiver, error) native;

  String get typeName() { return "PositionErrorCallback"; }
}
