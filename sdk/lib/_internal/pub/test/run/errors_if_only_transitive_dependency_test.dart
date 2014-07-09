// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration('Errors if the script is in a non-immediate dependency.', () {
    d.dir("foo", [
      d.libPubspec("foo", "1.0.0"),
      d.dir("bin", [
        d.file("bar.dart", "main() => print('foobar');")
      ])
    ]).create();

    d.dir("bar", [
      d.libPubspec("bar", "1.0.0", deps: {
        "foo": {"path": "../foo"}
      })
    ]).create();

    d.dir(appPath, [
      d.appPubspec({
        "bar": {"path": "../bar"}
      })
    ]).create();

    pubGet();

    var pub = pubRun(args: ["foo:script"]);
    pub.stderr.expect('Package "foo" is not an immediate dependency.');
    pub.stderr.expect('Cannot run executables in transitive dependencies.');
    pub.shouldExit(exit_codes.DATA);
  });
}
