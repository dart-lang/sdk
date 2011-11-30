// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ConsoleWrappingImplementation extends DOMWrapperBase implements Console {
  _ConsoleWrappingImplementation() : super() {}

  static create__ConsoleWrappingImplementation() native {
    return new _ConsoleWrappingImplementation();
  }

  MemoryInfo get memory() { return _get_memory(this); }
  static MemoryInfo _get_memory(var _this) native;

  void assert(bool condition) {
    _assert(this, condition);
    return;
  }
  static void _assert(receiver, condition) native;

  void count() {
    _count(this);
    return;
  }
  static void _count(receiver) native;

  void debug(Object arg) {
    _debug(this, arg);
    return;
  }
  static void _debug(receiver, arg) native;

  void dir() {
    _dir(this);
    return;
  }
  static void _dir(receiver) native;

  void dirxml() {
    _dirxml(this);
    return;
  }
  static void _dirxml(receiver) native;

  void error(Object arg) {
    _error(this, arg);
    return;
  }
  static void _error(receiver, arg) native;

  void group() {
    _group(this);
    return;
  }
  static void _group(receiver) native;

  void groupCollapsed() {
    _groupCollapsed(this);
    return;
  }
  static void _groupCollapsed(receiver) native;

  void groupEnd() {
    _groupEnd(this);
    return;
  }
  static void _groupEnd(receiver) native;

  void info(Object arg) {
    _info(this, arg);
    return;
  }
  static void _info(receiver, arg) native;

  void log(Object arg) {
    _log(this, arg);
    return;
  }
  static void _log(receiver, arg) native;

  void markTimeline() {
    _markTimeline(this);
    return;
  }
  static void _markTimeline(receiver) native;

  void time(String title) {
    _time(this, title);
    return;
  }
  static void _time(receiver, title) native;

  void timeEnd(String title) {
    _timeEnd(this, title);
    return;
  }
  static void _timeEnd(receiver, title) native;

  void timeStamp() {
    _timeStamp(this);
    return;
  }
  static void _timeStamp(receiver) native;

  void trace(Object arg) {
    _trace(this, arg);
    return;
  }
  static void _trace(receiver, arg) native;

  void warn(Object arg) {
    _warn(this, arg);
    return;
  }
  static void _warn(receiver, arg) native;

  String get typeName() { return "Console"; }
}
