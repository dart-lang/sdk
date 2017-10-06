// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

import "process_test_util.dart";

runEnvironmentProcess(Map environment, name, includeParent, callback) {
  var dartExecutable = Platform.executable;
  var printEnv = 'tests/standalone/io/print_env.dart';
  if (!new File(printEnv).existsSync()) {
    printEnv = '../$printEnv';
  }
  Process
      .run(dartExecutable, [printEnv, name],
          environment: environment, includeParentEnvironment: includeParent)
      .then((result) {
    if (result.exitCode != 0) {
      print('print_env.dart subprocess failed '
          'with exit code ${result.exitCode}');
      print('stdout:');
      print(result.stdout);
      print('stderr:');
      print(result.stderr);
    }
    Expect.equals(0, result.exitCode);
    callback(result.stdout);
  });
}

testEnvironment() {
  asyncStart();
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
        asyncEnd();
      });
    });
    // Only check one value to not spin up too many processes testing the
    // same things.
    break;
  }
}

testNoIncludeEnvironment() {
  asyncStart();
  var env = Platform.environment;
  Expect.isTrue(env.containsKey('PATH'));
  env = new Map.from(env);
  env.remove('PATH');
  runEnvironmentProcess(env, "PATH", false, (output) {
    Expect.isTrue(output.startsWith("null"));
    asyncEnd();
  });
}

main() {
  testEnvironment();
  testNoIncludeEnvironment();
}
