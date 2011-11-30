// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MessagePort extends EventTarget {

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  void close();

  bool dispatchEvent(Event evt);

  void postMessage(String message, [List messagePorts]);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

  void start();

  void webkitPostMessage(String message, [List transfer]);
}
