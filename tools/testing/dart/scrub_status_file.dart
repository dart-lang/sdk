// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tool for identifying stale test lines. Used when updating co19.
 *
 * Usage:
 * [: ./tools/testing/bin/$OS/dart tools/testing/dart/scrub_status_file.dart :]
 */

// TODO(ahe): Consider generalizing this.

#import('dart:io');

#import('status_file_parser.dart');

const List<String> CO19_STATUS_FILES = const <String>[
    'tests/co19/co19-compiler.status',
    'tests/co19/co19-dart2js.status',
    'tests/co19/co19-runtime.status'];

void onSectionsRead(String statusFile, List sections) {
  for (var section in sections) {
    for (var rule in section.testRules) {
      String name = rule.name;
      if (name == '*') continue;
      String path = 'tests/co19/src/$name.dart';
      File file = new File(path);
      if (!file.existsSync()) {
        print('$statusFile: $path: no such file');
      }
    }
  }
}

void readStatusFile(String path) {
  var sections = [];
  ReadConfigurationInto(path,
                        sections,
                        () => onSectionsRead(path, sections));
}

void main() {
  CO19_STATUS_FILES.forEach(readStatusFile);
}
