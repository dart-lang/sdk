// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _NotationWrappingImplementation extends _NodeWrappingImplementation implements Notation {
  _NotationWrappingImplementation() : super() {}

  static create__NotationWrappingImplementation() native {
    return new _NotationWrappingImplementation();
  }

  String get publicId() { return _get_publicId(this); }
  static String _get_publicId(var _this) native;

  String get systemId() { return _get_systemId(this); }
  static String _get_systemId(var _this) native;

  String get typeName() { return "Notation"; }
}
