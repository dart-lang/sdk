// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MessagePort extends EventTarget {

  MessagePortEvents get on();

  void _addEventListener(String type, EventListener listener, [bool useCapture]);

  void close();

  bool _dispatchEvent(Event evt);

  void postMessage(String message, [List messagePorts]);

  void _removeEventListener(String type, EventListener listener, [bool useCapture]);

  void start();

  void webkitPostMessage(String message, [List transfer]);
}

interface MessagePortEvents extends Events {

  EventListenerList get message();
}
