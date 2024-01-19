// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:path/path.dart' as path;
import 'package:test_package/has_part.dart' as has_part;

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

// Chop off the file name.
String baseDirectory = '${path.dirname(Platform.script.path)}/';
Uri baseUri = Platform.script.replace(path: baseDirectory);
Uri breakpointFile = baseUri.resolve('test_package/lib/the_part.dart');
const String shortFile = 'the_part.dart';

const int LINE = 88;

void code() {
  has_part.main();
}

final stops = <String>[];
const expected = <String>[
  '$shortFile:${LINE + 0}:5', // on 'print'
  '$shortFile:${LINE + 1}:3', // on class ending '}'
];

final tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtUriAndLine(breakpointFile.toString(), LINE),
  runStepThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected),
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'breakpoint_in_package_parts_class_file_uri_test.dart',
      testeeConcurrent: code,
      pauseOnStart: true,
      pauseOnExit: true,
    );
