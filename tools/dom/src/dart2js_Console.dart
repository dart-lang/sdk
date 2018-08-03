// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

class Console {
  const Console._safe();
  static const Console _safeConsole = const Console._safe();

  bool get _isConsoleDefined => JS('bool', 'typeof console != "undefined"');

  MemoryInfo get memory =>
      _isConsoleDefined ? JS('MemoryInfo', 'window.console.memory') : null;

  void assertCondition(bool condition, Object arg) => _isConsoleDefined
      ? JS('void', 'window.console.assertCondition(#, #)', condition, arg)
      : null;

  void clear(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.clear(#)', arg) : null;

  void count(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.count(#)', arg) : null;

  void debug(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.debug(#)', arg) : null;

  void dir(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.dir(#)', arg) : null;

  void dirxml(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.dirxml(#)', arg) : null;

  void error(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.error(#)', arg) : null;

  void group(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.group(#)', arg) : null;

  void groupCollapsed(Object arg) => _isConsoleDefined
      ? JS('void', 'window.console.groupCollapsed(#)', arg)
      : null;

  void groupEnd() =>
      _isConsoleDefined ? JS('void', 'window.console.groupEnd()') : null;

  void info(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.info(#)', arg) : null;

  void log(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.log(#)', arg) : null;

  void markTimeline(Object arg) => _isConsoleDefined
      ? JS('void', 'window.console.markTimeline(#)', arg)
      : null;

  void profile(String title) =>
      _isConsoleDefined ? JS('void', 'window.console.profile(#)', title) : null;

  void profileEnd(String title) => _isConsoleDefined
      ? JS('void', 'window.console.profileEnd(#)', title)
      : null;

  void table(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.table(#)', arg) : null;

  void time(String title) =>
      _isConsoleDefined ? JS('void', 'window.console.time(#)', title) : null;

  void timeEnd(String title) =>
      _isConsoleDefined ? JS('void', 'window.console.timeEnd(#)', title) : null;

  void timeStamp(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.timeStamp(#)', arg) : null;

  void trace(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.trace(#)', arg) : null;

  void warn(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.warn(#)', arg) : null;
}
