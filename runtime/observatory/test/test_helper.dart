// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_helper;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:unittest/unittest.dart';
import 'package:observatory/service_io.dart';

// This invocation should set up the state being tested.
const String _TESTEE_MODE_FLAG = "--testee-mode";

class _TestLauncher {
  Process process;
  final List<String> args;

  _TestLauncher() : args = ['--enable-vm-service:0',
                            Platform.script.toFilePath(),
                            _TESTEE_MODE_FLAG] {}

  Future<int> launch() {
    String dartExecutable = Platform.executable;
    var fullArgs = [];
    fullArgs.addAll(Platform.executableArguments);
    fullArgs.addAll(args);
    print('** Launching $fullArgs');
    return Process.start(dartExecutable, fullArgs).then((p) {

      Completer completer = new Completer();
      process = p;
      var portNumber;
      var blank;
      var first = true;
      process.stdout.transform(UTF8.decoder)
                    .transform(new LineSplitter()).listen((line) {
        if (line.startsWith('Observatory listening on http://')) {
          RegExp portExp = new RegExp(r"\d+.\d+.\d+.\d+:(\d+)");
          var port = portExp.firstMatch(line).group(1);
          portNumber = int.parse(port);
        }
        if (line == '') {
          // Received blank line.
          blank = true;
        }
        if (portNumber != null && blank == true && first == true) {
          completer.complete(portNumber);
          // Stop repeat completions.
          first = false;
          print('** Signaled to run test queries on $portNumber');
        }
        print(line);
      });
      process.stderr.transform(UTF8.decoder)
                    .transform(new LineSplitter()).listen((line) {
        print(line);
      });
      process.exitCode.then((exitCode) {
        expect(exitCode, equals(0));
      });
      return completer.future;
    });
  }

  void requestExit() {
    print('** Requesting script to exit.');
    process.stdin.add([32, 13, 10]);
  }
}

typedef Future IsolateTest(Isolate isolate);

/// Runs [tests] in sequence, each of which should take an [Isolate] and
/// return a [Future]. Code for setting up state can run before and/or
/// concurrently with the tests. Uses [mainArgs] to determine whether
/// to run tests or testee in this invokation of the script.
void runIsolateTests(List<String> mainArgs,
                     List<IsolateTest> tests,
                     {void testeeBefore(),
                      void testeeConcurrent()}) {
  if (mainArgs.contains(_TESTEE_MODE_FLAG)) {
    if (testeeBefore != null) {
      testeeBefore();
    }
    print(''); // Print blank line to signal that we are ready.
    if (testeeConcurrent != null) {
      testeeConcurrent();
    }
    // Wait until signaled from spawning test.
    stdin.first.then((_) => exit(0));
  } else {
    var process = new _TestLauncher();
    process.launch().then((port) {
      String addr = 'ws://localhost:$port/ws';
      new WebSocketVM(new WebSocketVMTarget(addr)).get('vm')
          .then((VM vm) => vm.isolates.first.load())
          .then((Isolate isolate) =>
              Future.forEach(tests, (test) => test(isolate)))
          .then((_) => exit(0));
    });
  }
}
