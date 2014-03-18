// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.test.util;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

void scheduleTempDir() {
  var tempDir;
  schedule(() {
    return Directory.systemTemp
        .createTemp('docgen_test-')
        .then((dir) {
      tempDir = dir;
      d.defaultRoot = tempDir.path;
    });
  });

  currentSchedule.onComplete.schedule(() {
    d.defaultRoot = null;
    return tempDir.delete(recursive: true);
  });
}

String getMultiLibraryCodePath() {
  var currentScript = p.fromUri(Platform.script);
  var codeDir = p.join(p.dirname(currentScript), 'multi_library_code');

  assert(FileSystemEntity.isDirectorySync(codeDir));

  return codeDir;
}

final Matcher hasSortedLines = predicate((String input) {
  var lines = new LineSplitter().convert(input);

  var sortedLines = new List.from(lines)..sort();

  var orderedMatcher = orderedEquals(sortedLines);
  return orderedMatcher.matches(lines, {});
}, 'String has sorted lines');

final Matcher isJsonMap = predicate((input) {
  try {
    return JSON.decode(input) is Map;
  } catch (e) {
    return false;
  }
}, 'Output is JSON encoded Map');
