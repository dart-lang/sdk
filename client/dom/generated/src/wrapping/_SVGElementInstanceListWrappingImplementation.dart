// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGElementInstanceListWrappingImplementation extends DOMWrapperBase implements SVGElementInstanceList {
  _SVGElementInstanceListWrappingImplementation() : super() {}

  static create__SVGElementInstanceListWrappingImplementation() native {
    return new _SVGElementInstanceListWrappingImplementation();
  }

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  SVGElementInstance item(int index) {
    return _item(this, index);
  }
  static SVGElementInstance _item(receiver, index) native;

  String get typeName() { return "SVGElementInstanceList"; }
}
