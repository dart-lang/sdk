// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Worker extends AbstractWorker default _WorkerFactoryProvider {

  Worker(String scriptUrl);

  WorkerEvents get on();

  void postMessage(Dynamic message, [List messagePorts]);

  void terminate();

  void webkitPostMessage(Dynamic message, [List messagePorts]);
}

interface WorkerEvents extends AbstractWorkerEvents {

  EventListenerList get message();
}
