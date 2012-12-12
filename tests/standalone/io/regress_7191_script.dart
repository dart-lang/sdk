// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

main() {
  // Open a port to make the script hang.
  var port = new ReceivePort();
  // Start sub-process when receiving data.
  stdin.onData = () {
    var data = stdin.read();
    var options = new Options();
    Process.start(options.executable, [options.script]).then((p) {
      p.stdout.onData = p.stdout.read;
      p.stderr.onData = p.stderr.read;
      // When receiving data again, kill sub-process and exit.
      stdin.onData = () {
        var data = stdin.read();
        Expect.listEquals([0], data);
        p.kill();
        p.onExit = exit;
      };
      // Close stdout. If handles are incorrectly inherited this will
      // not actually close stdout and the test will hang.
      stdout.close();
    });
  };
}
