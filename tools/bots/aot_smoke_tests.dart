#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Smoke test runner for Dart AOT (dart2aot, dartaotruntime).
// aot_smoke_tests.dart and dart_aot_test.dart together form the test that the
// AOT toolchain is compiled and included correctly in the SDK.
// This tests that the AOT tools can both successfully compile Dart -> AOT and
// run the resulting AOT blob with the AOT runtime.

import 'dart:io';
import 'dart:convert';

import 'package:args/args.dart';

get_dart2aot() {
  if (Platform.isLinux) {
    return 'out/ReleaseX64/dart-sdk/bin/dart2aot';
  } else if (Platform.isMacOS) {
    return 'xcodebuild/ReleaseX64/dart-sdk/bin/dart2aot';
  } else if (Platform.isWindows) {
    return 'out\\ReleaseX64\\dart-sdk\\bin\\dart2aot.bat';
  } else {
    throw 'Unsupported host platform!';
  }
}

get_dartaotruntime() {
  if (Platform.isLinux) {
    return 'out/ReleaseX64/dart-sdk/bin/dartaotruntime';
  } else if (Platform.isMacOS) {
    return 'xcodebuild/ReleaseX64/dart-sdk/bin/dartaotruntime';
  } else if (Platform.isWindows) {
    return 'out\\ReleaseX64\\dart-sdk\\bin\\dartaotruntime.exe';
  } else {
    throw 'Unsupported host platform!';
  }
}

assert_equals(var expected, var actual) {
  if (expected != actual) {
    print('Test failed! Expected \'$expected\', got \'$actual\'');
    exit(1);
  }
}

main(List<String> args) async {
  ProcessResult result;

  result = Process.runSync(get_dart2aot(),
      ['tools/bots/dart_aot_test.dart', 'tools/bots/dart_aot_test.dart.aot'],
      stdoutEncoding: utf8, stderrEncoding: utf8);
  stdout.write(result.stdout);
  if (result.exitCode != 0 || result.stderr != '') {
    stderr.write(result.stderr);
    exit(1);
  }

  result = Process.runSync(
      get_dartaotruntime(), ['tools/bots/dart_aot_test.dart.aot'],
      stdoutEncoding: utf8, stderrEncoding: utf8);
  if (result.exitCode != 0 || result.stderr != '') {
    stderr.write(result.stderr);
    exit(1);
  }

  assert_equals('Hello, 世界.', result.stdout.trim());
}
