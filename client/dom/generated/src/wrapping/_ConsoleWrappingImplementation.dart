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

  List get profiles() { return _get_profiles(this); }
  static List _get_profiles(var _this) native;

  void assertCondition(bool condition, Object arg) {
    _assertCondition(this, condition, arg);
    return;
  }
  static void _assertCondition(receiver, condition, arg) native;

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

  void group(Object arg) {
    _group(this, arg);
    return;
  }
  static void _group(receiver, arg) native;

  void groupCollapsed(Object arg) {
    _groupCollapsed(this, arg);
    return;
  }
  static void _groupCollapsed(receiver, arg) native;

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

  void profile(String title) {
    _profile(this, title);
    return;
  }
  static void _profile(receiver, title) native;

  void profileEnd(String title) {
    _profileEnd(this, title);
    return;
  }
  static void _profileEnd(receiver, title) native;

  void time(String title) {
    _time(this, title);
    return;
  }
  static void _time(receiver, title) native;

  void timeEnd(String title, Object arg) {
    _timeEnd(this, title, arg);
    return;
  }
  static void _timeEnd(receiver, title, arg) native;

  void timeStamp(Object arg) {
    _timeStamp(this, arg);
    return;
  }
  static void _timeStamp(receiver, arg) native;

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
