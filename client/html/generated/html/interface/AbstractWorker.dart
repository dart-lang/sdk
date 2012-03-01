// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AbstractWorker extends EventTarget {

  AbstractWorkerEvents get on();

  void _addEventListener(String type, EventListener listener, [bool useCapture]);

  bool _dispatchEvent(Event evt);

  void _removeEventListener(String type, EventListener listener, [bool useCapture]);
}

interface AbstractWorkerEvents extends Events {

  EventListenerList get error();
}
