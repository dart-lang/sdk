// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XMLHttpRequestUpload extends EventTarget {

  EventListener get onabort();

  void set onabort(EventListener value);

  EventListener get onerror();

  void set onerror(EventListener value);

  EventListener get onload();

  void set onload(EventListener value);

  EventListener get onloadstart();

  void set onloadstart(EventListener value);

  EventListener get onprogress();

  void set onprogress(EventListener value);

  void addEventListener(String type, EventListener listener, bool useCapture = null);

  bool dispatchEvent(Event evt);

  void removeEventListener(String type, EventListener listener, bool useCapture = null);
}
