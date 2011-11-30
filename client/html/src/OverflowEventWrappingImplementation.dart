// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class OverflowEventWrappingImplementation extends EventWrappingImplementation implements OverflowEvent {
  OverflowEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  /** @domName OverflowEvent.initOverflowEvent */
  factory OverflowEventWrappingImplementation(int orient,
      bool horizontalOverflow, bool verticalOverflow) {
    final e = dom.document.createEvent("OverflowEvent");
    e.initOverflowEvent(orient, horizontalOverflow, verticalOverflow);
    return LevelDom.wrapOverflowEvent(e);
  }

  bool get horizontalOverflow() => _ptr.horizontalOverflow;

  int get orient() => _ptr.orient;

  bool get verticalOverflow() => _ptr.verticalOverflow;
}
