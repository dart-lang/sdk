// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface TouchEvent extends UIEvent default TouchEventWrappingImplementation {

  TouchEvent(TouchList touches, TouchList targetTouches,
      TouchList changedTouches, String type, Window view, int screenX,
      int screenY, int clientX, int clientY, [bool ctrlKey, bool altKey,
      bool shiftKey, bool metaKey]);

  bool get altKey;

  TouchList get changedTouches;

  bool get ctrlKey;

  bool get metaKey;

  bool get shiftKey;

  TouchList get targetTouches;

  TouchList get touches;
}
