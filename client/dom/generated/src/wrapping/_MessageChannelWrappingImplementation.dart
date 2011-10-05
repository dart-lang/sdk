// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MessageChannelWrappingImplementation extends DOMWrapperBase implements MessageChannel {
  _MessageChannelWrappingImplementation() : super() {}

  static create__MessageChannelWrappingImplementation() native {
    return new _MessageChannelWrappingImplementation();
  }

  MessagePort get port1() { return _get__MessageChannel_port1(this); }
  static MessagePort _get__MessageChannel_port1(var _this) native;

  MessagePort get port2() { return _get__MessageChannel_port2(this); }
  static MessagePort _get__MessageChannel_port2(var _this) native;

  String get typeName() { return "MessageChannel"; }
}
