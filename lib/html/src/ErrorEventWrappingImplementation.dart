// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ErrorEventWrappingImplementation extends EventWrappingImplementation implements ErrorEvent {
  ErrorEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory ErrorEventWrappingImplementation(String type, String message,
      String filename, int lineNo, [bool canBubble = true,
      bool cancelable = true]) {
    final e = dom.document.createEvent("ErrorEvent");
    e.initErrorEvent(type, canBubble, cancelable, message, filename, lineNo);
    return LevelDom.wrapErrorEvent(e);
  }

  String get filename() => _ptr.filename;

  int get lineno() => _ptr.lineno;

  String get message() => _ptr.message;
}
