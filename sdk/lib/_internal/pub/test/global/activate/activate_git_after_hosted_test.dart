// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('activating a Git package deactivates the hosted one', () {
    ensureGit();

    servePackages((builder) {
      builder.serve("foo", "1.0.0", contents: [
        d.dir("bin", [
          d.file("foo.dart", "main(args) => print('hosted');")
        ])
      ]);
    });

    d.git('foo.git', [
      d.libPubspec("foo", "1.0.0"),
      d.dir("bin", [
        d.file("foo.dart", "main() => print('git');")
      ])
    ]).create();

    schedulePub(args: ["global", "activate", "foo"]);

    schedulePub(args: ["global", "activate", "-sgit", "../foo.git"],
        output: allOf(
            startsWith(
                'Package foo is currently active at version 1.0.0.\n'
                'Resolving dependencies...\n'
                '+ foo 1.0.0 from git ../foo.git at '),
            // Specific revision number goes here.
            endsWith(
                'Precompiling executables...\n'
                'Loading source assets...\n'
                'Precompiled foo:foo.\n'
                'Activated foo 1.0.0 from Git repository "../foo.git".')));

    // Should now run the git one.
    var pub = pubRun(global: true, args: ["foo"]);
    pub.stdout.expect("git");
    pub.shouldExit();
  });
}
