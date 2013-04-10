// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

main() {
  // Open a port to make the script hang.
  var port = new ReceivePort();
  // Start sub-process when receiving data.
  var subscription;
  subscription = stdin.listen((data) {
    var options = new Options();
    Process.start(options.executable, [options.script]).then((p) {
      p.stdout.listen((_) { });
      p.stderr.listen((_) { });
      // When receiving data again, kill sub-process and exit.
      subscription.onData((data) {
        p.kill();
        p.exitCode.then((_) => exit(0));
      });
      // Close stdout. If handles are incorrectly inherited this will
      // not actually close stdout and the test will hang.
      stdout.close();
    });
  });
}
