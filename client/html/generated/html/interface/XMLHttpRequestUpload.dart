// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XMLHttpRequestUpload extends EventTarget {

  XMLHttpRequestUploadEvents get on();

  void _addEventListener(String type, EventListener listener, [bool useCapture]);

  bool _dispatchEvent(Event evt);

  void _removeEventListener(String type, EventListener listener, [bool useCapture]);
}

interface XMLHttpRequestUploadEvents extends Events {

  EventListenerList get abort();

  EventListenerList get error();

  EventListenerList get load();

  EventListenerList get loadEnd();

  EventListenerList get loadStart();

  EventListenerList get progress();
}
