// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FrameSetElement extends Element {

  String cols;

  String rows;

  FrameSetElementEvents get on();
}

interface FrameSetElementEvents extends ElementEvents {

  EventListenerList get beforeUnload();

  EventListenerList get blur();

  EventListenerList get error();

  EventListenerList get focus();

  EventListenerList get hashChange();

  EventListenerList get load();

  EventListenerList get message();

  EventListenerList get offline();

  EventListenerList get online();

  EventListenerList get popState();

  EventListenerList get resize();

  EventListenerList get storage();

  EventListenerList get unload();
}
