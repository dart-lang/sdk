// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_helper;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TestLauncher {
  final String script;
  Process process;

  TestLauncher(this.script);

  String get scriptPath {
    var dartScript = Platform.script.toFilePath();
    var splitPoint = dartScript.lastIndexOf(Platform.pathSeparator);
    var scriptDirectory = dartScript.substring(0, splitPoint);
    return scriptDirectory + Platform.pathSeparator + script;
  }

  Future<int> launch() {
    String dartExecutable = Platform.executable;
    print('** Launching $scriptPath');
    return Process.start(dartExecutable,
                         ['--enable-vm-service:0', scriptPath]).then((p) {

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
      process.exitCode.then((code) {
        //Expect.equals(0, code, 'Launched dart executable exited with error.');
      });
      return completer.future;
    });
  }

  void requestExit() {
    print('** Requesting script to exit.');
    process.stdin.add([32, 13, 10]);
  }
}

