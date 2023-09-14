// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

class Changelog {
  static final fileName = 'CHANGELOG.md';

  void addEntry(RuleStateChange change, String rule) {
    var logFile = File(fileName);
    var lines = LineSplitter().convert(logFile.readAsStringSync());
    lines.insert(2, '- ${change.descriptionPrefix} lint: `$rule`');

    var output = StringBuffer();
    // ignore: prefer_foreach
    for (var line in lines) {
      output.writeln(line);
    }
    logFile.writeAsStringSync(output.toString());
  }

  String readCurrentRelease() {
    var logFile = File(fileName).readAsStringSync();
    for (var line in LineSplitter().convert(logFile)) {
      if (line.startsWith('#')) {
        return line.split('#')[1].trim();
      }
    }
    return 'UNKNOWN';
  }
}

enum RuleStateChange {
  added('new'),
  deprecated('deprecated'),
  removed('removed');

  final String descriptionPrefix;
  const RuleStateChange(this.descriptionPrefix);
}
