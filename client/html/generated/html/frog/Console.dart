// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _ConsoleImpl
    // Console is sometimes a singleton bag-of-properties without a prototype.
    implements Console 
    native "=(typeof console == 'undefined' ? {} : console)" {

  final _MemoryInfoImpl memory;

  final List profiles;

  void assertCondition(bool condition, Object arg) native;

  void count() native;

  void debug(Object arg) native;

  void dir() native;

  void dirxml() native;

  void error(Object arg) native;

  void group(Object arg) native;

  void groupCollapsed(Object arg) native;

  void groupEnd() native;

  void info(Object arg) native;

  void log(Object arg) native;

  void markTimeline() native;

  void profile(String title) native;

  void profileEnd(String title) native;

  void time(String title) native;

  void timeEnd(String title, Object arg) native;

  void timeStamp(Object arg) native;

  void trace(Object arg) native;

  void warn(Object arg) native;

}
