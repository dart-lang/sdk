// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CloseEventWrappingImplementation extends _EventWrappingImplementation implements CloseEvent {
  _CloseEventWrappingImplementation() : super() {}

  static create__CloseEventWrappingImplementation() native {
    return new _CloseEventWrappingImplementation();
  }

  int get code() { return _get_code(this); }
  static int _get_code(var _this) native;

  String get reason() { return _get_reason(this); }
  static String _get_reason(var _this) native;

  bool get wasClean() { return _get_wasClean(this); }
  static bool _get_wasClean(var _this) native;

  void initCloseEvent(String typeArg, bool canBubbleArg, bool cancelableArg, bool wasCleanArg, int codeArg, String reasonArg) {
    _initCloseEvent(this, typeArg, canBubbleArg, cancelableArg, wasCleanArg, codeArg, reasonArg);
    return;
  }
  static void _initCloseEvent(receiver, typeArg, canBubbleArg, cancelableArg, wasCleanArg, codeArg, reasonArg) native;

  String get typeName() { return "CloseEvent"; }
}
