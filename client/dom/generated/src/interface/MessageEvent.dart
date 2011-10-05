// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MessageEvent extends Event {

  String get data();

  String get lastEventId();

  MessagePort get messagePort();

  String get origin();

  DOMWindow get source();

  void initMessageEvent([String typeArg, bool canBubbleArg, bool cancelableArg, String dataArg, String originArg, String lastEventIdArg, DOMWindow sourceArg, MessagePort messagePort]);
}
