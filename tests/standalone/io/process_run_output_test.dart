// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test script for testing that output is handled correctly for
// non-interactive processes started with Process.run.

import "package:expect/expect.dart";
import "dart:convert";
import "dart:io";
import "process_test_util.dart";

checkOutput(String encoding, output) {
  if (encoding == 'ascii') {
    Expect.equals(output, 'abc');
  } else if (encoding == 'latin1') {
    Expect.equals(output, 'æøå');
  } else if (encoding == 'utf8') {
    Expect.listEquals(output.codeUnits, [955]);
  } else if (encoding == 'binary') {
    print(output);
    Expect.listEquals(output, [0, 1, 2]);
  }
}

test(scriptFile, String encoding, stream) {
  var enc;
  if (encoding == 'ascii') {
    enc = ascii;
  } else if (encoding == 'latin1') {
    enc = latin1;
  } else if (encoding == 'utf8') {
    enc = utf8;
  } else if (encoding == 'binary') {
    enc = null;
  }

  var args = <String>[]
    ..addAll(Platform.executableArguments)
    ..addAll([scriptFile, encoding, stream]);

  if (stream == 'stdout') {
    Process.run(Platform.executable, args, stdoutEncoding: enc).then((result) {
      Expect.equals(result.exitCode, 0);
      Expect.equals(result.stderr, '');
      checkOutput(encoding, result.stdout);
    });
  } else {
    Process.run(Platform.executable, args, stderrEncoding: enc).then((result) {
      Expect.equals(result.exitCode, 0);
      Expect.equals(result.stdout, '');
      checkOutput(encoding, result.stderr);
    });
  }
}

main() {
  var scriptFile = new File("tests/standalone/io/process_std_io_script2.dart");
  if (!scriptFile.existsSync()) {
    scriptFile = new File("../tests/standalone/io/process_std_io_script2.dart");
  }
  Expect.isTrue(scriptFile.existsSync());
  test(scriptFile.path, 'ascii', 'stdout');
  test(scriptFile.path, 'ascii', 'stderr');
  test(scriptFile.path, 'latin1', 'stdout');
  test(scriptFile.path, 'latin1', 'stderr');
  test(scriptFile.path, 'utf8', 'stdout');
  test(scriptFile.path, 'utf8', 'stderr');
  test(scriptFile.path, 'binary', 'stdout');
  test(scriptFile.path, 'binary', 'stderr');
}
