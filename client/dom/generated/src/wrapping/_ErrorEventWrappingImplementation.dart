// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ErrorEventWrappingImplementation extends _EventWrappingImplementation implements ErrorEvent {
  _ErrorEventWrappingImplementation() : super() {}

  static create__ErrorEventWrappingImplementation() native {
    return new _ErrorEventWrappingImplementation();
  }

  String get filename() { return _get__ErrorEvent_filename(this); }
  static String _get__ErrorEvent_filename(var _this) native;

  int get lineno() { return _get__ErrorEvent_lineno(this); }
  static int _get__ErrorEvent_lineno(var _this) native;

  String get message() { return _get__ErrorEvent_message(this); }
  static String _get__ErrorEvent_message(var _this) native;

  void initErrorEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String messageArg, String filenameArg, int linenoArg) {
    _initErrorEvent(this, typeArg, canBubbleArg, cancelableArg, messageArg, filenameArg, linenoArg);
    return;
  }
  static void _initErrorEvent(receiver, typeArg, canBubbleArg, cancelableArg, messageArg, filenameArg, linenoArg) native;

  String get typeName() { return "ErrorEvent"; }
}
