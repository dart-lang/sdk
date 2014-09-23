// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("the binstubs runs a precompiled snapshot if present", () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0", pubspec: {
        "executables": {
          "foo-script": "script"
        }
      }, contents: [
        d.dir("bin", [
          d.file("script.dart", "main(args) => print('ok');")
        ])
      ]);
    });

    schedulePub(args: ["global", "activate", "foo"]);

    d.dir(cachePath, [
      d.dir("bin", [
        d.matcherFile("foo-script", contains("script.dart.snapshot"))
      ])
    ]).validate();
  });
}
