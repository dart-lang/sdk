// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MessageEventWrappingImplementation extends _EventWrappingImplementation implements MessageEvent {
  _MessageEventWrappingImplementation() : super() {}

  static create__MessageEventWrappingImplementation() native {
    return new _MessageEventWrappingImplementation();
  }

  String get data() { return _get__MessageEvent_data(this); }
  static String _get__MessageEvent_data(var _this) native;

  String get lastEventId() { return _get__MessageEvent_lastEventId(this); }
  static String _get__MessageEvent_lastEventId(var _this) native;

  MessagePort get messagePort() { return _get__MessageEvent_messagePort(this); }
  static MessagePort _get__MessageEvent_messagePort(var _this) native;

  String get origin() { return _get__MessageEvent_origin(this); }
  static String _get__MessageEvent_origin(var _this) native;

  DOMWindow get source() { return _get__MessageEvent_source(this); }
  static DOMWindow _get__MessageEvent_source(var _this) native;

  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String dataArg, String originArg, String lastEventIdArg, DOMWindow sourceArg, MessagePort messagePort) {
    _initMessageEvent(this, typeArg, canBubbleArg, cancelableArg, dataArg, originArg, lastEventIdArg, sourceArg, messagePort);
    return;
  }
  static void _initMessageEvent(receiver, typeArg, canBubbleArg, cancelableArg, dataArg, originArg, lastEventIdArg, sourceArg, messagePort) native;

  String get typeName() { return "MessageEvent"; }
}
