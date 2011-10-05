// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TouchEvent extends UIEvent {

  bool get altKey();

  TouchList get changedTouches();

  bool get ctrlKey();

  bool get metaKey();

  bool get shiftKey();

  TouchList get targetTouches();

  TouchList get touches();

  void initTouchEvent(TouchList touches = null, TouchList targetTouches = null, TouchList changedTouches = null, String type = null, DOMWindow view = null, int screenX = null, int screenY = null, int clientX = null, int clientY = null, bool ctrlKey = null, bool altKey = null, bool shiftKey = null, bool metaKey = null);
}
