// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/7191.

// Starts a sub-process which in turn starts another sub-process and then closes
// its standard output. If handles are incorrectly inherited on Windows, this
// will lead to a situation where the stdout of the first sub-process is never
// closed which will make this test hang.

import 'dart:io';
import 'dart:isolate';

main() {
  var port = new ReceivePort();
  var options = new Options();
  var executable = options.executable;
  var scriptDir = new Path(options.script).directoryPath;
  var script = scriptDir.append('regress_7191_script.dart').toNativePath();
  Process.start(executable, [script]).then((process) {
    process.stdin.write([0]);
    process.stdout.onData = process.stdout.read;
    process.stderr.onData = process.stderr.read;
    process.stdout.onClosed = () {
      process.stdin.write([0]);
    };
    process.onExit = (exitCode) => port.close();
  });
}
