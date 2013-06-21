// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";
import "dart:isolate";
import "process_test_util.dart";

runEnvironmentProcess(Map environment, name, includeParent, callback) {
  var dartExecutable = new Options().executable;
  var printEnv = 'tests/standalone/io/print_env.dart';
  if (!new File(printEnv).existsSync()) {
    printEnv = '../$printEnv';
  }
  Process.run(dartExecutable,
              [printEnv, name],
              environment: environment,
              includeParentEnvironment: includeParent)
      .then((result) {
        Expect.equals(0, result.exitCode);
        callback(result.stdout);
      });
}

testEnvironment() {
  var donePort = new ReceivePort();
  Map env = Platform.environment;
  Expect.isFalse(env.isEmpty);
  // Check that some value in the environment stays the same when passed
  // to another process.
  for (var k in env.keys) {
    runEnvironmentProcess({}, k, true, (output) {
      // Only check startsWith. The print statements will add
      // newlines at the end.
      Expect.isTrue(output.startsWith(env[k]));
      // Add a new variable and check that it becomes an environment
      // variable in the child process.
      var copy = new Map.from(env);
      var name = 'MYENVVAR';
      while (env.containsKey(name)) name = '${name}_';
      copy[name] = 'value';
      runEnvironmentProcess(copy, name, true, (output) {
        Expect.isTrue(output.startsWith('value'));
        donePort.close();
      });
    });
    // Only check one value to not spin up too many processes testing the
    // same things.
    break;
  }
}

testNoIncludeEnvironment() {
  var donePort = new ReceivePort();
  runEnvironmentProcess({}, "PATH", false, (output) {
    donePort.close();
    Expect.isTrue(output.startsWith("null"));
  });
}

main() {
  testEnvironment();
  testNoIncludeEnvironment();
}
