// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface UIEvent extends Event {

  final int charCode;

  final int detail;

  final int keyCode;

  final int layerX;

  final int layerY;

  final int pageX;

  final int pageY;

  final DOMWindow view;

  final int which;

  void initUIEvent(String type, bool canBubble, bool cancelable, DOMWindow view, int detail);
}
