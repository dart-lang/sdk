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
  integration("responds with a 404 for missing source files", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir("lib", [d.file("nope.dart", "nope")]),
            d.dir("web", [d.file("index.html", "<body>"),])]).create();

    // Start the server with the files present so that it creates barback
    // assets for them.
    pubServe();

    // Now delete them.
    schedule(() {
      deleteEntry(path.join(sandboxDir, appPath, "lib", "nope.dart"));
      deleteEntry(path.join(sandboxDir, appPath, "web", "index.html"));
    }, "delete files");

    // Now request them.
    // TODO(rnystrom): It's possible for these requests to happen quickly
    // enough that the file system hasn't notified for the deletions yet. If
    // that happens, we can probably just add a short delay here.

    requestShould404("index.html");
    requestShould404("packages/myapp/nope.dart");
    requestShould404("dir/packages/myapp/nope.dart");
    endPubServe();
  });
}
