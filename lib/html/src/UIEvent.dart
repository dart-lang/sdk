// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface UIEvent extends Event default UIEventWrappingImplementation {

  UIEvent(String type, Window view, int detail, [bool canBubble,
      bool cancelable]);

  int get charCode;

  int get detail;

  int get keyCode;

  int get layerX;

  int get layerY;

  int get pageX;

  int get pageY;

  Window get view;

  int get which;
}
