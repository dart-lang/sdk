// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Worker extends AbstractWorker {

  EventListener get onmessage();

  void set onmessage(EventListener value);

  void postMessage(String message, [List messagePorts]);

  void terminate();

  void webkitPostMessage(String message, [List messagePorts]);
}
