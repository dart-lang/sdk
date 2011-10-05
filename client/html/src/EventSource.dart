// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface EventSourceEvents extends Events {
  EventListenerList get error();
  EventListenerList get message();
  EventListenerList get open();
}

interface EventSource extends EventTarget {

  static final int CLOSED = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  String get URL();

  int get readyState();

  void close();

  EventSourceEvents get on();
}
