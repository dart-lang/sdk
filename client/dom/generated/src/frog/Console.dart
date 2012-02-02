// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _ConsoleJs
    // Implement DOMType directly.  Console is sometimes a singleton
    // bag-of-properties without a prototype, so it can't inherit from
    // DOMTypeJs.
    implements Console, DOMType
    native "=(typeof console == 'undefined' ? {} : console)" {

  _MemoryInfoJs get memory() native "return this.memory;";

  List get profiles() native "return this.profiles;";

  void assertCondition(bool condition) native;

  void count() native;

  void debug(Object arg) native;

  void dir() native;

  void dirxml() native;

  void error(Object arg) native;

  void group() native;

  void groupCollapsed() native;

  void groupEnd() native;

  void info(Object arg) native;

  void log(Object arg) native;

  void markTimeline() native;

  void profile(String title) native;

  void profileEnd(String title) native;

  void time(String title) native;

  void timeEnd(String title) native;

  void timeStamp() native;

  void trace(Object arg) native;

  void warn(Object arg) native;


  // Keep these in sync with frog_DOMTypeJs.dart.
  var dartObjectLocalStorage;
  String get typeName() native;
}
