// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('dart:io');
#import('dart:isolate');
#source('process_test_util.dart');

runEnvironmentProcess(Map environment, name, callback) {
  var dartExecutable = getDartFileName();
  var options = new ProcessOptions();
  options.environment = environment;
  var printEnv = 'tests/standalone/io/print_env.dart';
  if (!new File(printEnv).existsSync()) {
    printEnv = '../$printEnv';
  }
  var process = new Process.run(dartExecutable,
                                [printEnv, name],
                                options,
                                (exit, out, err) {
    Expect.equals(0, exit);
    callback(out);
  });
  process.onError = (e) => Expect.fail("Unexpected process start error: '$e'");
}

testEnvironment() {
  var donePort = new ReceivePort();
  Map env = Platform.environment;
  Expect.isFalse(env.isEmpty());
  // Check that some value in the environment stays the same when passed
  // to another process.
  for (var k in env.getKeys()) {
    runEnvironmentProcess(env, k, (output) {
      // Only check startsWith. The print statements will add
      // newlines at the end.
      Expect.isTrue(output.startsWith(env[k]));
      // Add a new variable and check that it becomes an environment
      // variable in the child process.
      var copy = new Map.from(env);
      var name = 'MYENVVAR';
      while (env.containsKey(name)) name = '${name}_';
      copy[name] = 'value';
      runEnvironmentProcess(copy, name, (output) {
        Expect.isTrue(output.startsWith('value'));
        donePort.close();
      });
    });
    // Only check one value to not spin up too many processes testing the
    // same things.
    break;
  }
}

main() {
  testEnvironment();
}
