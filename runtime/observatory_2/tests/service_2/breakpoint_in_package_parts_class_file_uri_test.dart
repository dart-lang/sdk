// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library breakpoint_in_parts_class;

import 'dart:io' show Platform;

import 'package:observatory_test_package_2/has_part.dart' as hasPart;
import 'package:path/path.dart' as path;
import 'test_helper.dart';
import 'service_test_common.dart';

// Chop off the file name.
String baseDirectory = path.dirname(Platform.script.path) + '/';
Uri baseUri = Platform.script.replace(path: baseDirectory);
Uri breakpointFile =
    baseUri.resolve('observatory_test_package_2/the_part.dart');
const String shortFile = "the_part.dart";

const int LINE = 87;

code() {
  hasPart.main();
}

List<String> stops = [];

List<String> expected = [
  "$shortFile:${LINE + 0}:5", // on 'print'
  "$shortFile:${LINE + 1}:3" // on class ending '}'
];

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtUriAndLine(breakpointFile.toString(), LINE),
  runStepThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected)
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: code, pause_on_start: true, pause_on_exit: true);
}
