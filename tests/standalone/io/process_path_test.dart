// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that the executable is looked up on the user's PATH when spawning a
// process.

#import('dart:io');

main() {
  // Pick an app that we expect to be on the PATH that returns 0 when run with
  // no arguments.
  var executable = Platform.operatingSystem == 'windows' ? 'cmd.exe' : 'true';

  var options = new ProcessOptions();
  Process.run(executable, []).then((result) {
    Expect.equals(0, result.exitCode);
  });
}
