// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  // This is a regression test for http://dartbug.com/21402.
  initConfig();
  withBarbackVersions("any", () {
    integration("picks up files replaced after serving started when using the "
        "native watcher", () {
      d.dir(appPath, [
        d.pubspec({
          "name": "myapp",
          "transformers": ["myapp/src/transformer"]
        }),
        d.dir("lib", [d.dir("src", [
          d.file("transformer.dart", REWRITE_TRANSFORMER)
        ])]),
        d.dir("web", [
          d.file("file.txt", "before"),
        ]),
        d.file("other", "after")
      ]).create();

      createLockFile("myapp", pkg: ["barback"]);

      pubServe(args: ["--no-force-poll"]);
      waitForBuildSuccess();
      requestShouldSucceed("file.out", "before.out");

      schedule(() {
        // Replace file.txt by renaming other on top of it.
        return new File(p.join(sandboxDir, appPath, "other"))
            .rename(p.join(sandboxDir, appPath, "web", "file.txt"));
      });

      // Read the transformed file to ensure the change is actually noticed by
      // pub and not that we just get the new file contents piped through
      // without pub realizing they've changed.
      waitForBuildSuccess();
      requestShouldSucceed("file.out", "after.out");

      endPubServe();
    });
  });
}
