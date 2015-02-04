// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('defaults to the package name if the script is omitted', () {
    servePackages((builder) {
      builder.serve(
          "foo",
          "1.0.0",
          contents: [d.dir("bin", [d.file("foo.dart", "main(args) => print('foo');")])]);
    });

    schedulePub(args: ["global", "activate", "foo"]);

    var pub = pubRun(global: true, args: ["foo"]);
    pub.stdout.expect("foo");
    pub.shouldExit();
  });
}
