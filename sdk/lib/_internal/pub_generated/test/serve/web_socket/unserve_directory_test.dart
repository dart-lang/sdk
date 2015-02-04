// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  initConfig();
  integration("unbinds a directory from a port", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir("test", [d.file("index.html", "<test body>")]),
            d.dir("web", [d.file("index.html", "<body>")])]).create();

    pubServe();

    requestShouldSucceed("index.html", "<body>");
    requestShouldSucceed("index.html", "<test body>", root: "test");

    // Unbind the directory.
    expectWebSocketResult("unserveDirectory", {
      "path": "test"
    }, {
      "url": getServerUrl("test")
    });

    // "test" should not be served now.
    requestShouldNotConnect("index.html", root: "test");

    // "web" is still fine.
    requestShouldSucceed("index.html", "<body>");

    endPubServe();
  });
}
