// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ClientRectListWrappingImplementation extends DOMWrapperBase implements ClientRectList {
  _ClientRectListWrappingImplementation() : super() {}

  static create__ClientRectListWrappingImplementation() native {
    return new _ClientRectListWrappingImplementation();
  }

  int get length() { return _get__ClientRectList_length(this); }
  static int _get__ClientRectList_length(var _this) native;

  ClientRect item([int index = null]) {
    if (index === null) {
      return _item(this);
    } else {
      return _item_2(this, index);
    }
  }
  static ClientRect _item(receiver) native;
  static ClientRect _item_2(receiver, index) native;

  String get typeName() { return "ClientRectList"; }
}
