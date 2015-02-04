// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';

const SCRIPT = """
import 'dart:io';

main() {
  print("started");
  var line1 = stdin.readLineSync();
  print("between");
  var line2 = stdin.readLineSync();
  print(line1);
  print(line2);
}
""";

main() {
  initConfig();
  integration('the spawned application can read from stdin', () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("bin", [d.file("script.dart", SCRIPT)])]).create();

    var pub = pubRun(args: ["script"]);

    pub.stdout.expect("started");
    pub.writeLine("first");
    pub.stdout.expect("between");
    pub.writeLine("second");
    pub.stdout.expect("first");
    pub.stdout.expect("second");
    pub.shouldExit(0);
  });
}
