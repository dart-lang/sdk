// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface DOMApplicationCacheEvents extends Events {
  EventListenerList get cached();
  EventListenerList get checking();
  EventListenerList get downloading();
  EventListenerList get error();
  EventListenerList get noUpdate();
  EventListenerList get obsolete();
  EventListenerList get progress();
  EventListenerList get updateReady();  
}

interface DOMApplicationCache extends EventTarget {

  static final int CHECKING = 2;

  static final int DOWNLOADING = 3;

  static final int IDLE = 1;

  static final int OBSOLETE = 5;

  static final int UNCACHED = 0;

  static final int UPDATEREADY = 4;

  int get status();

  void swapCache();

  void update();

  DOMApplicationCacheEvents get on();
}
