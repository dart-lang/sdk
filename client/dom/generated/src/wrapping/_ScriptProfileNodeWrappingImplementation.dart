// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ScriptProfileNodeWrappingImplementation extends DOMWrapperBase implements ScriptProfileNode {
  _ScriptProfileNodeWrappingImplementation() : super() {}

  static create__ScriptProfileNodeWrappingImplementation() native {
    return new _ScriptProfileNodeWrappingImplementation();
  }

  int get callUID() { return _get_callUID(this); }
  static int _get_callUID(var _this) native;

  List get children() { return _get_children(this); }
  static List _get_children(var _this) native;

  String get functionName() { return _get_functionName(this); }
  static String _get_functionName(var _this) native;

  int get lineNumber() { return _get_lineNumber(this); }
  static int _get_lineNumber(var _this) native;

  int get numberOfCalls() { return _get_numberOfCalls(this); }
  static int _get_numberOfCalls(var _this) native;

  num get selfTime() { return _get_selfTime(this); }
  static num _get_selfTime(var _this) native;

  num get totalTime() { return _get_totalTime(this); }
  static num _get_totalTime(var _this) native;

  String get url() { return _get_url(this); }
  static String _get_url(var _this) native;

  bool get visible() { return _get_visible(this); }
  static bool _get_visible(var _this) native;

  String get typeName() { return "ScriptProfileNode"; }
}
