// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _EntityWrappingImplementation extends _NodeWrappingImplementation implements Entity {
  _EntityWrappingImplementation() : super() {}

  static create__EntityWrappingImplementation() native {
    return new _EntityWrappingImplementation();
  }

  String get notationName() { return _get_notationName(this); }
  static String _get_notationName(var _this) native;

  String get publicId() { return _get_publicId(this); }
  static String _get_publicId(var _this) native;

  String get systemId() { return _get_systemId(this); }
  static String _get_systemId(var _this) native;

  String get typeName() { return "Entity"; }
}
