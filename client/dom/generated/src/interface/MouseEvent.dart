// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MouseEvent extends UIEvent {

  bool get altKey();

  int get button();

  int get clientX();

  int get clientY();

  bool get ctrlKey();

  Node get fromElement();

  bool get metaKey();

  int get offsetX();

  int get offsetY();

  EventTarget get relatedTarget();

  int get screenX();

  int get screenY();

  bool get shiftKey();

  Node get toElement();

  int get x();

  int get y();

  void initMouseEvent(String type = null, bool canBubble = null, bool cancelable = null, DOMWindow view = null, int detail = null, int screenX = null, int screenY = null, int clientX = null, int clientY = null, bool ctrlKey = null, bool altKey = null, bool shiftKey = null, bool metaKey = null, int button = null, EventTarget relatedTarget = null);
}
