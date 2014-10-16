// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  initConfig();
  integration(
      "binds a directory to a new port and immediately requests an "
          "asset URL from that server",
      () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir("test", [d.file("index.html", "<test body>")]),
            d.dir("web", [d.file("index.html", "<body>")])]).create();

    pubServe(args: ["web"]);

    // Bind the new directory.
    expect(webSocketRequest("serveDirectory", {
      "path": "test"
    }), completes);

    expectWebSocketResult("pathToUrls", {
      "path": "test/index.html"
    }, {
      "urls": [endsWith("/index.html")]
    });

    endPubServe();
  });
}
