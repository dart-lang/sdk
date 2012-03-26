// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MessageEventWrappingImplementation extends EventWrappingImplementation implements MessageEvent {
  MessageEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory MessageEventWrappingImplementation(String type, String data,
      String origin, String lastEventId, Window source, MessagePort port,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("MessageEvent");
    e.initMessageEvent(type, canBubble, cancelable, data, origin, lastEventId,
        LevelDom.unwrap(source), LevelDom.unwrap(port));
    return LevelDom.wrapMessageEvent(e);
  }

  String get data() => _ptr.data;

  String get lastEventId() => _ptr.lastEventId;

  MessagePort get messagePort() => LevelDom.wrapMessagePort(_ptr.messagePort);

  String get origin() => _ptr.origin;

  Window get source() => LevelDom.wrapWindow(_ptr.source);
}
