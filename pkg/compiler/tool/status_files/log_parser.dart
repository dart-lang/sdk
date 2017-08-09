// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library status_files.log_parser;

import 'record.dart';

final RegExp _stackRE = new RegExp('#[0-9]* ');

/// Extracts test records from a test.py [log].
List<Record> parse(String log) {
  var records = [];
  var suite;
  var test;
  var config;
  var expected;
  var actual;
  var reason;
  var fullReason; // lines before stack, usually multiline reason.
  var stack = [];
  var paragraph = []; // collector of lines for fullReason.
  bool reproIsNext = false;
  for (var line in log.split('\n')) {
    if (line.startsWith("FAILED: ")) {
      int space = line.lastIndexOf(' ');
      test = line.substring(space + 1).trim();
      suite = '';
      var slash = test.indexOf('/');
      if (slash > 0) {
        suite = test.substring(0, slash).trim();
        test = test.substring(slash + 1).trim();
      }
      config = line
          .substring("FAILED: ".length, space)
          .replaceAll('release_ia32', '')
          .replaceAll('release_x64', '');
    }
    if (line.startsWith("Expected: ")) {
      expected = line.substring("Expected: ".length).trim();
    }
    if (line.startsWith("Actual: ")) {
      actual = line.substring("Actual: ".length).trim();
    }
    if (line.startsWith("The compiler crashed:")) {
      reason = line.substring("The compiler crashed:".length).trim();
      paragraph.clear();
    }

    if (line.startsWith(_stackRE)) {
      stack.add(line);
      fullReason ??= paragraph.take(5).join('\n');
      paragraph.clear();
    } else {
      paragraph.add(line);
    }

    if (reproIsNext) {
      records.add(new Record(suite, test, config, expected, actual, reason,
          line.trim(), fullReason, stack));
      suite = test = config = expected = actual = reason = null;
      stack = [];
      fullReason = null;
      paragraph.clear();
      reproIsNext = false;
    }
    if (line.startsWith("Short reproduction command (experimental):")) {
      reproIsNext = true;
    }
  }
  return records;
}
