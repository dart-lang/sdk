// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Notification extends EventTarget {

  String get dir();

  void set dir(String value);

  EventListener get onclick();

  void set onclick(EventListener value);

  EventListener get onclose();

  void set onclose(EventListener value);

  EventListener get ondisplay();

  void set ondisplay(EventListener value);

  EventListener get onerror();

  void set onerror(EventListener value);

  String get replaceId();

  void set replaceId(String value);

  void addEventListener(String type, EventListener listener, bool useCapture = null);

  void cancel();

  bool dispatchEvent(Event evt);

  void removeEventListener(String type, EventListener listener, bool useCapture = null);

  void show();
}
