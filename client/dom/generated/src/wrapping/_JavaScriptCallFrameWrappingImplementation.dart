// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _JavaScriptCallFrameWrappingImplementation extends DOMWrapperBase implements JavaScriptCallFrame {
  _JavaScriptCallFrameWrappingImplementation() : super() {}

  static create__JavaScriptCallFrameWrappingImplementation() native {
    return new _JavaScriptCallFrameWrappingImplementation();
  }

  JavaScriptCallFrame get caller() { return _get__JavaScriptCallFrame_caller(this); }
  static JavaScriptCallFrame _get__JavaScriptCallFrame_caller(var _this) native;

  int get column() { return _get__JavaScriptCallFrame_column(this); }
  static int _get__JavaScriptCallFrame_column(var _this) native;

  String get functionName() { return _get__JavaScriptCallFrame_functionName(this); }
  static String _get__JavaScriptCallFrame_functionName(var _this) native;

  int get line() { return _get__JavaScriptCallFrame_line(this); }
  static int _get__JavaScriptCallFrame_line(var _this) native;

  int get sourceID() { return _get__JavaScriptCallFrame_sourceID(this); }
  static int _get__JavaScriptCallFrame_sourceID(var _this) native;

  String get type() { return _get__JavaScriptCallFrame_type(this); }
  static String _get__JavaScriptCallFrame_type(var _this) native;

  void evaluate(String script) {
    _evaluate(this, script);
    return;
  }
  static void _evaluate(receiver, script) native;

  int scopeType(int scopeIndex) {
    return _scopeType(this, scopeIndex);
  }
  static int _scopeType(receiver, scopeIndex) native;

  String get typeName() { return "JavaScriptCallFrame"; }
}
