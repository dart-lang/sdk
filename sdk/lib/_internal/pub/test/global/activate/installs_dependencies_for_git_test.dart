// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('activating a Git package installs its dependencies', () {
    servePackages([
      packageMap("bar", "1.0.0", {"baz": "any"}),
      packageMap("baz", "1.0.0")
    ]);

    d.git('foo.git', [
      d.libPubspec("foo", "1.0.0", deps: {
        "bar": "any"
      }),
      d.dir("bin", [
        d.file("foo.dart", "main() => print('ok');")
      ])
    ]).create();

    schedulePub(args: ["global", "activate", "-sgit", "../foo.git"],
        output: allOf([
      contains("Downloading bar 1.0.0..."),
      contains("Downloading baz 1.0.0...")
    ]));
  });
}
