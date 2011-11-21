// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGPathSegWrappingImplementation extends DOMWrapperBase implements SVGPathSeg {
  _SVGPathSegWrappingImplementation() : super() {}

  static create__SVGPathSegWrappingImplementation() native {
    return new _SVGPathSegWrappingImplementation();
  }

  int get pathSegType() { return _get_pathSegType(this); }
  static int _get_pathSegType(var _this) native;

  String get pathSegTypeAsLetter() { return _get_pathSegTypeAsLetter(this); }
  static String _get_pathSegTypeAsLetter(var _this) native;

  String get typeName() { return "SVGPathSeg"; }
}
