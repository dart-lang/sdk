// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebKitAnimationListWrappingImplementation extends DOMWrapperBase implements WebKitAnimationList {
  _WebKitAnimationListWrappingImplementation() : super() {}

  static create__WebKitAnimationListWrappingImplementation() native {
    return new _WebKitAnimationListWrappingImplementation();
  }

  int get length() { return _get__WebKitAnimationList_length(this); }
  static int _get__WebKitAnimationList_length(var _this) native;

  WebKitAnimation item(int index) {
    return _item(this, index);
  }
  static WebKitAnimation _item(receiver, index) native;

  String get typeName() { return "WebKitAnimationList"; }
}
