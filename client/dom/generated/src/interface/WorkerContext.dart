// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WorkerGlobalScope {

  WorkerLocation get location();

  void set location(WorkerLocation value);

  WorkerNavigator get navigator();

  void set navigator(WorkerNavigator value);

  EventListener get onerror();

  void set onerror(EventListener value);

  NotificationCenter get webkitNotifications();

  DOMURL get webkitURL();

  void addEventListener(String type, EventListener listener, bool useCapture = null);

  void clearInterval(int handle = null);

  void clearTimeout(int handle = null);

  void close();

  bool dispatchEvent(Event evt);

  void importScripts();

  void removeEventListener(String type, EventListener listener, bool useCapture = null);

  int setInterval(TimeoutHandler handler, int timeout);

  int setTimeout(TimeoutHandler handler, int timeout);
}

interface WorkerContext extends WorkerGlobalScope {
}
