// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration('Errors if the script in a dependency does not exist.', () {
    d.dir("foo", [
      d.libPubspec("foo", "1.0.0")
    ]).create();

    d.dir(appPath, [
      d.appPubspec({
        "foo": {"path": "../foo"}
      })
    ]).create();

    pubGet();

    var pub = pubRun(args: ["foo:script"]);
    pub.stderr.expect("Could not find bin/script.dart in package foo.");
    pub.shouldExit(exit_codes.NO_INPUT);
  });
}
