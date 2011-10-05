// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Event {

  static final int AT_TARGET = 2;

  static final int BLUR = 8192;

  static final int BUBBLING_PHASE = 3;

  static final int CAPTURING_PHASE = 1;

  static final int CHANGE = 32768;

  static final int CLICK = 64;

  static final int DBLCLICK = 128;

  static final int DRAGDROP = 2048;

  static final int FOCUS = 4096;

  static final int KEYDOWN = 256;

  static final int KEYPRESS = 1024;

  static final int KEYUP = 512;

  static final int MOUSEDOWN = 1;

  static final int MOUSEDRAG = 32;

  static final int MOUSEMOVE = 16;

  static final int MOUSEOUT = 8;

  static final int MOUSEOVER = 4;

  static final int MOUSEUP = 2;

  static final int SELECT = 16384;

  bool get bubbles();

  bool get cancelBubble();

  void set cancelBubble(bool value);

  bool get cancelable();

  EventTarget get currentTarget();

  bool get defaultPrevented();

  int get eventPhase();

  bool get returnValue();

  void set returnValue(bool value);

  EventTarget get srcElement();

  EventTarget get target();

  int get timeStamp();

  String get type();

  void initEvent([String eventTypeArg, bool canBubbleArg, bool cancelableArg]);

  void preventDefault();

  void stopImmediatePropagation();

  void stopPropagation();
}
