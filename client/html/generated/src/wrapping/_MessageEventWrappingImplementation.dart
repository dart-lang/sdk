// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MessageEventWrappingImplementation extends EventWrappingImplementation implements MessageEvent {
  MessageEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get data() { return _ptr.data; }

  String get lastEventId() { return _ptr.lastEventId; }

  MessagePort get messagePort() { return LevelDom.wrapMessagePort(_ptr.messagePort); }

  String get origin() { return _ptr.origin; }

  Window get source() { return LevelDom.wrapWindow(_ptr.source); }

  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String dataArg, String originArg, String lastEventIdArg, Window sourceArg, MessagePort messagePort) {
    _ptr.initMessageEvent(typeArg, canBubbleArg, cancelableArg, dataArg, originArg, lastEventIdArg, LevelDom.unwrap(sourceArg), LevelDom.unwrap(messagePort));
    return;
  }
}
