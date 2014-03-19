// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as p;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  initConfig();
  integration("when a subdirectory is unbound it is still watched because the "
      "superdirectory is watching it", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("example", [
        d.dir("one", [
          d.file("foo.txt", "before")
        ])
      ])
    ]).create();

    var exampleOne = p.join("example", "one");
    pubServe(args: ["example", exampleOne]);

    requestShouldSucceed("one/foo.txt", "before", root: "example");
    requestShouldSucceed("foo.txt", "before", root: exampleOne);

    // Unbind the subdirectory.
    expectWebSocketCall({
      "command": "unserveDirectory",
      "path": exampleOne
    }, replyEquals: {
      "url": getServerUrl(exampleOne)
    });

    // "example/one" should not be served now.
    requestShouldNotConnect("foo.txt", root: exampleOne);

    // "example" is still fine.
    requestShouldSucceed("one/foo.txt", "before", root: "example");

    // And still being watched.
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("example", [
        d.dir("one", [
          d.file("foo.txt", "after")
        ])
      ])
    ]).create();

    waitForBuildSuccess();
    requestShouldSucceed("one/foo.txt", "after", root: "example");

    endPubServe();
  });
}
