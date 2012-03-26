// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CustomEventWrappingImplementation extends EventWrappingImplementation implements CustomEvent {
  CustomEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory CustomEventWrappingImplementation(String type,
      [bool canBubble = true, bool cancelable = true, Object detail = null]) {
    final e = dom.document.createEvent("CustomEvent");
    e.initCustomEvent(type, canBubble, cancelable, detail);
    return LevelDom.wrapCustomEvent(e);
  }

  String get detail() => _ptr.detail;
}
