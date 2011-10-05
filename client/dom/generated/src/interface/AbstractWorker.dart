// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AbstractWorker extends EventTarget {

  EventListener get onerror();

  void set onerror(EventListener value);

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  bool dispatchEvent(Event evt);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);
}
