// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface TouchEvent extends UIEvent {

  final bool altKey;

  final TouchList changedTouches;

  final bool ctrlKey;

  final bool metaKey;

  final bool shiftKey;

  final TouchList targetTouches;

  final TouchList touches;

  void initTouchEvent(TouchList touches, TouchList targetTouches, TouchList changedTouches, String type, Window view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey);
}
