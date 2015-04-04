// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../descriptor.dart' as d;
import '../test_pub.dart';

const SCRIPT = """
import 'dart:io';

main() {
  ProcessSignal.SIGHUP.watch().listen(print);

  print("ready");
}
""";

main() {
  initConfig();
  integration('forwards signals to the inner script', () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("bin", [
        d.file("script.dart", SCRIPT)
      ])
    ]).create();

    var pub = pubRun(args: ["bin/script"]);

    pub.stdout.expect("ready");
    pub.signal(Process.SIGINT);
    pub.stdout.expect("SIGINT");

    pub.kill();
  });
}
