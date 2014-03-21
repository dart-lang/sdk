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
  integration("when a superdirectory is unbound it is still watched because "
      "the subdirectory is watching it", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("example", [
        d.dir("one", [
          d.file("foo.txt", "before")
        ])
      ])
    ]).create();

    var exampleOne = p.join("example", "one");
    pubServe(args: [exampleOne, "example"]);

    requestShouldSucceed("one/foo.txt", "before", root: "example");
    requestShouldSucceed("foo.txt", "before", root: exampleOne);

    // Unbind the subdirectory.
    expectWebSocketResult("unserveDirectory", {"path": "example"}, {
      "url": getServerUrl("example")
    });

    // "example" should not be served now.
    requestShouldNotConnect("one/foo.txt", root: "example");

    // "example/one" is still fine.
    requestShouldSucceed("foo.txt", "before", root: exampleOne);

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
    requestShouldSucceed("foo.txt", "after", root: exampleOne);

    endPubServe();
  });
}
