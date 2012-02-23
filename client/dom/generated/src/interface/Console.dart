// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Console {

  final MemoryInfo memory;

  final List profiles;

  void assertCondition(bool condition, Object arg);

  void count();

  void debug(Object arg);

  void dir();

  void dirxml();

  void error(Object arg);

  void group(Object arg);

  void groupCollapsed(Object arg);

  void groupEnd();

  void info(Object arg);

  void log(Object arg);

  void markTimeline();

  void profile(String title);

  void profileEnd(String title);

  void time(String title);

  void timeEnd(String title, Object arg);

  void timeStamp(Object arg);

  void trace(Object arg);

  void warn(Object arg);
}
