// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MessageChannelWrappingImplementation extends DOMWrapperBase implements MessageChannel {
  MessageChannelWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  MessagePort get port1() { return LevelDom.wrapMessagePort(_ptr.port1); }

  MessagePort get port2() { return LevelDom.wrapMessagePort(_ptr.port2); }
}
