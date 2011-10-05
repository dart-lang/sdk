// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ConsoleWrappingImplementation extends DOMWrapperBase implements Console {
  ConsoleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void count() {
    _ptr.count();
    return;
  }

  void debug(Object arg) {
    _ptr.debug(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  void dir() {
    _ptr.dir();
    return;
  }

  void dirxml() {
    _ptr.dirxml();
    return;
  }

  void error(Object arg) {
    _ptr.error(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  void group() {
    _ptr.group();
    return;
  }

  void groupCollapsed() {
    _ptr.groupCollapsed();
    return;
  }

  void groupEnd() {
    _ptr.groupEnd();
    return;
  }

  void info(Object arg) {
    _ptr.info(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  void log(Object arg) {
    _ptr.log(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  void markTimeline() {
    _ptr.markTimeline();
    return;
  }

  void time(String title) {
    _ptr.time(title);
    return;
  }

  void timeEnd(String title) {
    _ptr.timeEnd(title);
    return;
  }

  void timeStamp() {
    _ptr.timeStamp();
    return;
  }

  void trace(Object arg) {
    _ptr.trace(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  void warn(Object arg) {
    _ptr.warn(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  String get typeName() { return "Console"; }
}
