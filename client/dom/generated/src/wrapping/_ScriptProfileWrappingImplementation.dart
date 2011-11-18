// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ScriptProfileWrappingImplementation extends DOMWrapperBase implements ScriptProfile {
  _ScriptProfileWrappingImplementation() : super() {}

  static create__ScriptProfileWrappingImplementation() native {
    return new _ScriptProfileWrappingImplementation();
  }

  ScriptProfileNode get head() { return _get_head(this); }
  static ScriptProfileNode _get_head(var _this) native;

  String get title() { return _get_title(this); }
  static String _get_title(var _this) native;

  int get uid() { return _get_uid(this); }
  static int _get_uid(var _this) native;

  String get typeName() { return "ScriptProfile"; }
}
