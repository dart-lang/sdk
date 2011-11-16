// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WheelEvent extends UIEvent {

  bool get altKey();

  int get clientX();

  int get clientY();

  bool get ctrlKey();

  bool get metaKey();

  int get offsetX();

  int get offsetY();

  int get screenX();

  int get screenY();

  bool get shiftKey();

  int get wheelDelta();

  int get wheelDeltaX();

  int get wheelDeltaY();

  int get x();

  int get y();

  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, DOMWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey);
}
