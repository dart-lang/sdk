// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WheelEvent extends UIEvent {

  final bool altKey;

  final int clientX;

  final int clientY;

  final bool ctrlKey;

  final bool metaKey;

  final int offsetX;

  final int offsetY;

  final int screenX;

  final int screenY;

  final bool shiftKey;

  final bool webkitDirectionInvertedFromDevice;

  final int wheelDelta;

  final int wheelDeltaX;

  final int wheelDeltaY;

  final int x;

  final int y;

  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, DOMWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey);
}
