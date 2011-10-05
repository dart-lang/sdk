// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface ApplicationCache extends EventTarget {

  EventListener get oncached();

  void set oncached(EventListener value);

  EventListener get onchecking();

  void set onchecking(EventListener value);

  EventListener get ondownloading();

  void set ondownloading(EventListener value);

  EventListener get onerror();

  void set onerror(EventListener value);

  EventListener get onnoupdate();

  void set onnoupdate(EventListener value);

  EventListener get onobsolete();

  void set onobsolete(EventListener value);

  EventListener get onprogress();

  void set onprogress(EventListener value);

  EventListener get onupdateready();

  void set onupdateready(EventListener value);

  int get status();

  void addEventListener(String type, EventListener listener, bool useCapture = null);

  bool dispatchEvent(Event evt);

  void removeEventListener(String type, EventListener listener, bool useCapture = null);

  void swapCache();

  void update();
}

interface DOMApplicationCache extends ApplicationCache {

  static final int CHECKING = 2;

  static final int DOWNLOADING = 3;

  static final int IDLE = 1;

  static final int OBSOLETE = 5;

  static final int UNCACHED = 0;

  static final int UPDATEREADY = 4;
}
