// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ShadowRootWrappingImplementation extends _NodeWrappingImplementation implements ShadowRoot {
  _ShadowRootWrappingImplementation() : super() {}

  static create__ShadowRootWrappingImplementation() native {
    return new _ShadowRootWrappingImplementation();
  }

  Element get host() { return _get_host(this); }
  static Element _get_host(var _this) native;

  String get typeName() { return "ShadowRoot"; }
}
