// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../lib/src/io.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("stop serving a file that is removed", () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("web", [d.file("index.html", "body")])]).create();

    pubServe();
    requestShouldSucceed("index.html", "body");

    schedule(
        () => deleteEntry(path.join(sandboxDir, appPath, "web", "index.html")));

    waitForBuildSuccess();
    requestShould404("index.html");
    endPubServe();
  });
}
