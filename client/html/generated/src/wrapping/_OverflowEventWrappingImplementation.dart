// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OverflowEventWrappingImplementation extends EventWrappingImplementation implements OverflowEvent {
  OverflowEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get horizontalOverflow() { return _ptr.horizontalOverflow; }

  int get orient() { return _ptr.orient; }

  bool get verticalOverflow() { return _ptr.verticalOverflow; }

  void initOverflowEvent(int orient, bool horizontalOverflow, bool verticalOverflow) {
    _ptr.initOverflowEvent(orient, horizontalOverflow, verticalOverflow);
    return;
  }
}
