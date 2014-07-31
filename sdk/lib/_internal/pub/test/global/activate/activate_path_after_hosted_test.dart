// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('activating a hosted package deactivates the path one', () {
    servePackages([
      packageMap("foo", "1.0.0")
    ], contents: [
      d.dir("bin", [
        d.file("foo.dart", "main(args) => print('hosted');")
      ])
    ]);

    d.dir("foo", [
      d.libPubspec("foo", "2.0.0"),
      d.dir("bin", [
        d.file("foo.dart", "main() => print('path');")
      ])
    ]).create();

    schedulePub(args: ["global", "activate", "foo"]);
    schedulePub(args: ["global", "activate", "-spath", "../foo"], output: """
        Package foo is already active at version 1.0.0.
        Activated foo 2.0.0.""");

    // Should now run the path one.
    var pub = pubRun(global: true, args: ["foo"]);
    pub.stdout.expect("path");
    pub.shouldExit();
  });
}
