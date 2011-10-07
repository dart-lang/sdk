// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ErrorEventWrappingImplementation extends EventWrappingImplementation implements ErrorEvent {
  ErrorEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get filename() { return _ptr.filename; }

  int get lineno() { return _ptr.lineno; }

  String get message() { return _ptr.message; }

  void initErrorEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String messageArg, String filenameArg, int linenoArg) {
    _ptr.initErrorEvent(typeArg, canBubbleArg, cancelableArg, messageArg, filenameArg, linenoArg);
    return;
  }
}
