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

  void initMessageEvent([String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, String dataArg = null, String originArg = null, String lastEventIdArg = null, DOMWindow sourceArg = null, MessagePort messagePort = null]) {
    if (typeArg === null) {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (dataArg === null) {
            if (originArg === null) {
              if (lastEventIdArg === null) {
                if (sourceArg === null) {
                  if (messagePort === null) {
                    _initMessageEvent(this);
                    return;
                  }
                }
              }
            }
          }
        }
      }
    } else {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (dataArg === null) {
            if (originArg === null) {
              if (lastEventIdArg === null) {
                if (sourceArg === null) {
                  if (messagePort === null) {
                    _initMessageEvent_2(this, typeArg);
                    return;
                  }
                }
              }
            }
          }
        }
      } else {
        if (cancelableArg === null) {
          if (dataArg === null) {
            if (originArg === null) {
              if (lastEventIdArg === null) {
                if (sourceArg === null) {
                  if (messagePort === null) {
                    _initMessageEvent_3(this, typeArg, canBubbleArg);
                    return;
                  }
                }
              }
            }
          }
        } else {
          if (dataArg === null) {
            if (originArg === null) {
              if (lastEventIdArg === null) {
                if (sourceArg === null) {
                  if (messagePort === null) {
                    _initMessageEvent_4(this, typeArg, canBubbleArg, cancelableArg);
                    return;
                  }
                }
              }
            }
          } else {
            if (originArg === null) {
              if (lastEventIdArg === null) {
                if (sourceArg === null) {
                  if (messagePort === null) {
                    _initMessageEvent_5(this, typeArg, canBubbleArg, cancelableArg, dataArg);
                    return;
                  }
                }
              }
            } else {
              if (lastEventIdArg === null) {
                if (sourceArg === null) {
                  if (messagePort === null) {
                    _initMessageEvent_6(this, typeArg, canBubbleArg, cancelableArg, dataArg, originArg);
                    return;
                  }
                }
              } else {
                if (sourceArg === null) {
                  if (messagePort === null) {
                    _initMessageEvent_7(this, typeArg, canBubbleArg, cancelableArg, dataArg, originArg, lastEventIdArg);
                    return;
                  }
                } else {
                  if (messagePort === null) {
                    _initMessageEvent_8(this, typeArg, canBubbleArg, cancelableArg, dataArg, originArg, lastEventIdArg, sourceArg);
                    return;
                  } else {
                    _initMessageEvent_9(this, typeArg, canBubbleArg, cancelableArg, dataArg, originArg, lastEventIdArg, sourceArg, messagePort);
                    return;
                  }
                }
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initMessageEvent(receiver) native;
  static void _initMessageEvent_2(receiver, typeArg) native;
  static void _initMessageEvent_3(receiver, typeArg, canBubbleArg) native;
  static void _initMessageEvent_4(receiver, typeArg, canBubbleArg, cancelableArg) native;
  static void _initMessageEvent_5(receiver, typeArg, canBubbleArg, cancelableArg, dataArg) native;
  static void _initMessageEvent_6(receiver, typeArg, canBubbleArg, cancelableArg, dataArg, originArg) native;
  static void _initMessageEvent_7(receiver, typeArg, canBubbleArg, cancelableArg, dataArg, originArg, lastEventIdArg) native;
  static void _initMessageEvent_8(receiver, typeArg, canBubbleArg, cancelableArg, dataArg, originArg, lastEventIdArg, sourceArg) native;
  static void _initMessageEvent_9(receiver, typeArg, canBubbleArg, cancelableArg, dataArg, originArg, lastEventIdArg, sourceArg, messagePort) native;

  String get typeName() { return "MessageEvent"; }
}
