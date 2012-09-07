// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface MessageEvent extends Event default MessageEventWrappingImplementation {

  MessageEvent(String type, String data, String origin, String lastEventId,
      Window source, MessagePort port, [bool canBubble, bool cancelable]);

  String get data;

  String get lastEventId;

  MessagePort get messagePort;

  String get origin;

  Window get source;
}
