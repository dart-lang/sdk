// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:expect/expect.dart";

import "process_test_util.dart";

void testProcessRunBinaryOutput() {
  var result = Process.runSync(
      getProcessTestFileName(), const ["0", "0", "0", "0"],
      stdoutEncoding: null);
  Expect.isTrue(result.stdout is List<int>);
  Expect.isTrue(result.stderr is String);

  result = Process.runSync(getProcessTestFileName(), const ["0", "0", "0", "0"],
      stderrEncoding: null);
  Expect.isTrue(result.stdout is String);
  Expect.isTrue(result.stderr is List<int>);

  result = Process.runSync(getProcessTestFileName(), const ["0", "0", "0", "0"],
      stdoutEncoding: null, stderrEncoding: null);
  Expect.isTrue(result.stdout is List<int>);
  Expect.isTrue(result.stderr is List<int>);
}

void main() {
  testProcessRunBinaryOutput();
}
