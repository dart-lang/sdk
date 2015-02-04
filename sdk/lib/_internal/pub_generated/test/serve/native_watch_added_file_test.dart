// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

// TODO(nweiz): Default to testing the native watcher and add an explicit test
// for the polling watcher when issue 14941 is fixed.

main() {
  initConfig();
  integration(
      "picks up files added after serving started when using the " "native watcher",
      () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("web", [d.file("index.html", "body")])]).create();

    pubServe(args: ["--no-force-poll"]);
    waitForBuildSuccess();
    requestShouldSucceed("index.html", "body");

    d.dir(appPath, [d.dir("web", [d.file("other.html", "added")])]).create();

    waitForBuildSuccess();
    requestShouldSucceed("other.html", "added");
    endPubServe();
  });
}
