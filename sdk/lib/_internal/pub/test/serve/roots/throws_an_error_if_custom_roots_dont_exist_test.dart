// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../../lib/src/exit_codes.dart' as exit_codes;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  initConfig();
  integration("throws an error if custom roots don't exist", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("baz")
    ]).create();

    var server = startPubServe(args: ["foo", "bar", "baz"]);
    server.stderr.expect('Directories "bar" and "foo" don\'t exist.');
    server.shouldExit(exit_codes.USAGE);
  });
}
