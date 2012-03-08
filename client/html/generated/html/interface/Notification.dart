// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Notification extends EventTarget {

  NotificationEvents get on();

  String dir;

  String replaceId;

  void cancel();

  void show();
}

interface NotificationEvents extends Events {

  EventListenerList get click();

  EventListenerList get close();

  EventListenerList get display();

  EventListenerList get error();

  EventListenerList get show();
}
