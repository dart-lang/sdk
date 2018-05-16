// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

class Console {
  const Console._safe();
  static const Console _safeConsole = const Console._safe();

  bool get _isConsoleDefined => JS('bool', 'typeof console != "undefined"');

  @DomName('Console.memory')
  MemoryInfo get memory =>
      _isConsoleDefined ? JS('MemoryInfo', 'window.console.memory') : null;

  @DomName('Console.assertCondition')
  void assertCondition(bool condition, Object arg) => _isConsoleDefined
      ? JS('void', 'window.console.assertCondition(#, #)', condition, arg)
      : null;

  @DomName('Console.clear')
  void clear(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.clear(#)', arg) : null;

  @DomName('Console.count')
  void count(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.count(#)', arg) : null;

  @DomName('Console.debug')
  void debug(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.debug(#)', arg) : null;

  @DomName('Console.dir')
  void dir(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.dir(#)', arg) : null;

  @DomName('Console.dirxml')
  void dirxml(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.dirxml(#)', arg) : null;

  @DomName('Console.error')
  void error(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.error(#)', arg) : null;

  @DomName('Console.group')
  void group(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.group(#)', arg) : null;

  @DomName('Console.groupCollapsed')
  void groupCollapsed(Object arg) => _isConsoleDefined
      ? JS('void', 'window.console.groupCollapsed(#)', arg)
      : null;

  @DomName('Console.groupEnd')
  void groupEnd() =>
      _isConsoleDefined ? JS('void', 'window.console.groupEnd()') : null;

  @DomName('Console.info')
  void info(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.info(#)', arg) : null;

  @DomName('Console.log')
  void log(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.log(#)', arg) : null;

  @DomName('Console.markTimeline')
  void markTimeline(Object arg) => _isConsoleDefined
      ? JS('void', 'window.console.markTimeline(#)', arg)
      : null;

  @DomName('Console.profile')
  void profile(String title) =>
      _isConsoleDefined ? JS('void', 'window.console.profile(#)', title) : null;

  @DomName('Console.profileEnd')
  void profileEnd(String title) => _isConsoleDefined
      ? JS('void', 'window.console.profileEnd(#)', title)
      : null;

  @DomName('Console.table')
  void table(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.table(#)', arg) : null;

  @DomName('Console.time')
  void time(String title) =>
      _isConsoleDefined ? JS('void', 'window.console.time(#)', title) : null;

  @DomName('Console.timeEnd')
  void timeEnd(String title) =>
      _isConsoleDefined ? JS('void', 'window.console.timeEnd(#)', title) : null;

  @DomName('Console.timeStamp')
  void timeStamp(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.timeStamp(#)', arg) : null;

  @DomName('Console.trace')
  void trace(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.trace(#)', arg) : null;

  @DomName('Console.warn')
  void warn(Object arg) =>
      _isConsoleDefined ? JS('void', 'window.console.warn(#)', arg) : null;
}
