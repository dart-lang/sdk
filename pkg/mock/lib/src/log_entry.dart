// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock.log_entry;

import 'package:matcher/matcher.dart';

import 'action.dart';
import 'util.dart';

/**
 * Every call to a [Mock] object method is logged. The logs are
 * kept in instances of [LogEntry].
 */
class LogEntry {
  /** The time of the event. */
  DateTime time;

  /** The mock object name, if any. */
  final String mockName;

  /** The method name. */
  final String methodName;

  /** The parameters. */
  final List args;

  /** The behavior that resulted. */
  final Action action;

  /** The value that was returned (if no throw). */
  final value;

  LogEntry(this.mockName, this.methodName,
      this.args, this.action, [this.value]) {
    time = new DateTime.now();
  }

  String _pad2(int val) => (val >= 10 ? '$val' : '0$val');

  String toString([DateTime baseTime]) {
    Description d = new StringDescription();
    if (baseTime == null) {
      // Show absolute time.
      d.add('${time.hour}:${_pad2(time.minute)}:'
          '${_pad2(time.second)}.${time.millisecond}>  ');
    } else {
      // Show relative time.
      int delta = time.millisecondsSinceEpoch - baseTime.millisecondsSinceEpoch;
      int secs = delta ~/ 1000;
      int msecs = delta % 1000;
      d.add('$secs.$msecs>  ');
    }
    d.add('${qualifiedName(mockName, methodName)}(');
    if (args != null) {
      for (var i = 0; i < args.length; i++) {
        if (i != 0) d.add(', ');
        d.addDescriptionOf(args[i]);
      }
    }
    d.add(') ${action == Action.THROW ? "threw" : "returned"} ');
    d.addDescriptionOf(value);
    return d.toString();
  }
}
