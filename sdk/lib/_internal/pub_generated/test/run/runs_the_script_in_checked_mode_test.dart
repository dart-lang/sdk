// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

const SCRIPT = """
main() {
  int a = true;
}
""";

main() {
  initConfig();
  integration('runs the script in checked mode by default', () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("bin", [d.file("script.dart", SCRIPT)])]).create();

    schedulePub(
        args: ["run", "script"],
        error: contains("'bool' is not a subtype of type 'int' of 'a'"),
        exitCode: 255);
  });
}
