// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CloseEventWrappingImplementation extends EventWrappingImplementation implements CloseEvent {
  CloseEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory CloseEventWrappingImplementation(String type, int code, String reason,
      [bool canBubble = true, bool cancelable = true, bool wasClean = true]) {
    final e = dom.document.createEvent("CloseEvent");
    e.initCloseEvent(type, canBubble, cancelable, wasClean, code, reason);
    return LevelDom.wrapCloseEvent(e);
  }

  int get code => _ptr.code;

  String get reason => _ptr.reason;

  bool get wasClean => _ptr.wasClean;
}
