// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EventSource extends EventTarget {

  static final int CLOSED = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  String get URL();

  EventListener get onerror();

  void set onerror(EventListener value);

  EventListener get onmessage();

  void set onmessage(EventListener value);

  EventListener get onopen();

  void set onopen(EventListener value);

  int get readyState();

  void addEventListener(String type, EventListener listener, bool useCapture = null);

  void close();

  bool dispatchEvent(Event evt);

  void removeEventListener(String type, EventListener listener, bool useCapture = null);
}
