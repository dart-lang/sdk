// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _BarInfoWrappingImplementation extends DOMWrapperBase implements BarInfo {
  _BarInfoWrappingImplementation() : super() {}

  static create__BarInfoWrappingImplementation() native {
    return new _BarInfoWrappingImplementation();
  }

  bool get visible() { return _get_visible(this); }
  static bool _get_visible(var _this) native;

  String get typeName() { return "BarInfo"; }
}
