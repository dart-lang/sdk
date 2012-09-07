// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class PageTransitionEventWrappingImplementation extends EventWrappingImplementation implements PageTransitionEvent {
  PageTransitionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory PageTransitionEventWrappingImplementation(String type,
      [bool canBubble = true, bool cancelable = true,
      bool persisted = false]) {
    final e = dom.document.createEvent("PageTransitionEvent");
    e.initPageTransitionEvent(type, canBubble, cancelable, persisted);
    return LevelDom.wrapPageTransitionEvent(e);
  }

  bool get persisted => _ptr.persisted;
}
