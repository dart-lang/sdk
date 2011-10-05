// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface AbstractWorkerEvents extends Events {
  EventListenerList get error();
}

interface AbstractWorker extends EventTarget {
  AbstractWorkerEvents get on();
}
