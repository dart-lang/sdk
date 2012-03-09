// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface MouseEvent extends UIEvent default _MouseEventFactoryProvider {

  MouseEvent(String type, Window view, int detail, int screenX, int screenY,
      int clientX, int clientY, int button, [bool canBubble, bool cancelable,
      bool ctrlKey, bool altKey, bool shiftKey, bool metaKey,
      EventTarget relatedTarget]);


  final bool altKey;

  final int button;

  final int clientX;

  final int clientY;

  final bool ctrlKey;

  final Clipboard dataTransfer;

  final Node fromElement;

  final bool metaKey;

  final int offsetX;

  final int offsetY;

  final EventTarget relatedTarget;

  final int screenX;

  final int screenY;

  final bool shiftKey;

  final Node toElement;

  final int x;

  final int y;
}
