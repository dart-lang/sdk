// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _VoidCallbackWrappingImplementation extends DOMWrapperBase implements VoidCallback {
  _VoidCallbackWrappingImplementation() : super() {}

  static create__VoidCallbackWrappingImplementation() native {
    return new _VoidCallbackWrappingImplementation();
  }

  void handleEvent() {
    _handleEvent(this);
    return;
  }
  static void _handleEvent(receiver) native;

  String get typeName() { return "VoidCallback"; }
}
