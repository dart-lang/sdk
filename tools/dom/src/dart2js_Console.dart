// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

class Console {
  const Console._safe();
  static const Console _safeConsole = const Console._safe();

  bool get _isConsoleDefined => JS('bool', 'typeof console != "undefined"');

  MemoryInfo? get memory =>
      _isConsoleDefined ? JS('MemoryInfo', 'window.console.memory') : null;

  // Even though many of the following JS methods can take in multiple
  // arguments, we historically and currently limit the number of variable
  // arguments to 1. Depending on the need, these methods may be updated to
  // allow for more.

  // We rename assert to assertCondition here.
  void assertCondition([bool? condition, Object? arg]) => _isConsoleDefined
      ? JS('void', 'window.console.assert(#, #)', condition, arg)
      : null;

  // clear no longer takes in an argument, but we keep this as optional to
  // maintain backwards compatibility.
  void clear([Object? arg]) =>
      _isConsoleDefined ? JS('void', 'window.console.clear(#)', arg) : null;

  // count takes in a String instead, but we keep this as an Object for
  // backwards compatibility.
  void count([Object? arg]) =>
      _isConsoleDefined ? JS('void', 'window.console.count(#)', arg) : null;

  void countReset([String? arg]) => _isConsoleDefined
      ? JS('void', 'window.console.countReset(#)', arg)
      : null;

  void debug(Object? arg) =>
      _isConsoleDefined ? JS('void', 'window.console.debug(#)', arg) : null;

  void dir([Object? item, Object? options]) => _isConsoleDefined
      ? JS('void', 'window.console.dir(#, #)', item, options)
      : null;

  void dirxml(Object? arg) =>
      _isConsoleDefined ? JS('void', 'window.console.dirxml(#)', arg) : null;

  void error(Object? arg) =>
      _isConsoleDefined ? JS('void', 'window.console.error(#)', arg) : null;

  void group(Object? arg) =>
      _isConsoleDefined ? JS('void', 'window.console.group(#)', arg) : null;

  void groupCollapsed(Object? arg) => _isConsoleDefined
      ? JS('void', 'window.console.groupCollapsed(#)', arg)
      : null;

  void groupEnd() =>
      _isConsoleDefined ? JS('void', 'window.console.groupEnd()') : null;

  void info(Object? arg) =>
      _isConsoleDefined ? JS('void', 'window.console.info(#)', arg) : null;

  void log(Object? arg) =>
      _isConsoleDefined ? JS('void', 'window.console.log(#)', arg) : null;

  void table([Object? tabularData, List<String>? properties]) =>
      _isConsoleDefined
          ? JS('void', 'window.console.table(#, #)', tabularData, properties)
          : null;

  void time([String? label]) =>
      _isConsoleDefined ? JS('void', 'window.console.time(#)', label) : null;

  void timeEnd([String? label]) =>
      _isConsoleDefined ? JS('void', 'window.console.timeEnd(#)', label) : null;

  void timeLog([String? label, Object? arg]) => _isConsoleDefined
      ? JS('void', 'window.console.timeLog(#, #)', label, arg)
      : null;

  void trace(Object? arg) =>
      _isConsoleDefined ? JS('void', 'window.console.trace(#)', arg) : null;

  void warn(Object? arg) =>
      _isConsoleDefined ? JS('void', 'window.console.warn(#)', arg) : null;

  // The following are non-standard methods.
  void profile([String? title]) =>
      _isConsoleDefined ? JS('void', 'window.console.profile(#)', title) : null;

  void profileEnd([String? title]) => _isConsoleDefined
      ? JS('void', 'window.console.profileEnd(#)', title)
      : null;

  void timeStamp([Object? arg]) =>
      _isConsoleDefined ? JS('void', 'window.console.timeStamp(#)', arg) : null;

  // The following is deprecated and should be removed once we drop support for
  // older Safari browsers.
  void markTimeline(Object? arg) => _isConsoleDefined
      ? JS('void', 'window.console.markTimeline(#)', arg)
      : null;
}
