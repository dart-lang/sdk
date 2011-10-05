// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DedicatedWorkerGlobalScope extends WorkerContext {

  EventListener get onmessage();

  void set onmessage(EventListener value);

  void postMessage(Object message);

  void webkitPostMessage(Object message);
}

interface DedicatedWorkerContext extends DedicatedWorkerGlobalScope {
}
