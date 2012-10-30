// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that the executable is looked up on the user's PATH when spawning a
// process and environment variables are passed in.

#import('dart:io');

main() {
  // Pick an app that we expect to be on the PATH that returns 0 when run with
  // no arguments.
  var executable = 'true';
  var args = [];
  if (Platform.operatingSystem == 'windows') {
    executable = 'cmd.exe';
    args = ['/C', 'echo', '"ok"'];
  }

  var options = new ProcessOptions();
  options.environment = new Map.from(Platform.environment);
  options.environment['whatever'] = 'something';

  Process.run(executable, args, options).then((result) {
    Expect.equals(0, result.exitCode);
  });
}
