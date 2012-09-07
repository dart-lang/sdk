// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface XMLHttpRequestUploadEvents extends Events {
  EventListenerList get abort;
  EventListenerList get error;
  EventListenerList get load;
  EventListenerList get loadStart;
  EventListenerList get progress;
}

interface XMLHttpRequestUpload extends EventTarget {
  XMLHttpRequestUploadEvents get on;
}
