// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';

const SCRIPT = """
main(List<String> args) {
  print(args.join(" "));
}
""";

main() {
  initConfig();
  integration('passes arguments to the spawned script', () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("bin", [d.file("args.dart", SCRIPT)])]).create();

    // Use some args that would trip up pub's arg parser to ensure that it
    // isn't trying to look at them.
    var pub = pubRun(args: ["args", "--verbose", "-m", "--", "help"]);

    pub.stdout.expect("--verbose -m -- help");
    pub.shouldExit();
  });
}
