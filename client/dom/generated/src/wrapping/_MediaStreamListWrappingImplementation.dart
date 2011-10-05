// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MediaStreamListWrappingImplementation extends DOMWrapperBase implements MediaStreamList {
  _MediaStreamListWrappingImplementation() : super() {}

  static create__MediaStreamListWrappingImplementation() native {
    return new _MediaStreamListWrappingImplementation();
  }

  int get length() { return _get__MediaStreamList_length(this); }
  static int _get__MediaStreamList_length(var _this) native;

  MediaStream item(int index) {
    return _item(this, index);
  }
  static MediaStream _item(receiver, index) native;

  String get typeName() { return "MediaStreamList"; }
}
