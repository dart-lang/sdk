// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _NavigatorUserMediaSuccessCallbackWrappingImplementation extends DOMWrapperBase implements NavigatorUserMediaSuccessCallback {
  _NavigatorUserMediaSuccessCallbackWrappingImplementation() : super() {}

  static create__NavigatorUserMediaSuccessCallbackWrappingImplementation() native {
    return new _NavigatorUserMediaSuccessCallbackWrappingImplementation();
  }

  bool handleEvent(LocalMediaStream stream) {
    return _handleEvent(this, stream);
  }
  static bool _handleEvent(receiver, stream) native;

  String get typeName() { return "NavigatorUserMediaSuccessCallback"; }
}
