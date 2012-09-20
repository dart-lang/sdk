// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file starts a trivial HTTP server to serve locale data files. We start
 * it as a separate process, then terminate so that the test can continue to
 * run. See web_server.dart for more information.
 */

#import("dart:io");
#import("dart:isolate");

main() {
  // TODO(alanknight): This uses nohup and & to stop the child process from
  // stopping when we exit. This won't work on Windows.
  var p = Process.start(
      "nohup",
      [new Options().executable, "pkg/intl/test/web_server.dart", "&"]);
  p.onExit = (p) => print("Exited abnormally with exit code: $p");
  // Give the other process a moment to fully start, and give us a meaningful
  // exit code if there's an abnormal exit, before we finish.
  new Timer(1000, (t) => exit(0));
}