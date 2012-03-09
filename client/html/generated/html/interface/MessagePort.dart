// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MessagePort extends EventTarget {

  MessagePortEvents get on();

  void close();

  void postMessage(String message, [List messagePorts]);

  void start();

  void webkitPostMessage(String message, [List transfer]);
}

interface MessagePortEvents extends Events {

  EventListenerList get message();
}
