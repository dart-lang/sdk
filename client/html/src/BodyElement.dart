// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface BodyElementEvents extends ElementEvents {
  EventListenerList get beforeUnload();
  EventListenerList get hashChange();
  EventListenerList get message();
  EventListenerList get offline();
  EventListenerList get online();
  EventListenerList get orientationChange();
  EventListenerList get popState();
  EventListenerList get resize();
  EventListenerList get storage();
  EventListenerList get unLoad();
}

interface BodyElement extends Element { 
  BodyElementEvents get on();
}
