// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  // TODO(rnystrom): Split into independent tests.
  initConfig();
  integration("assetIdToUrls converts asset ids to matching URL paths", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("test", [
        d.file("index.html", "<body>"),
        d.dir("sub", [
          d.file("bar.html", "bar"),
        ])
      ]),
      d.dir("web", [
        d.file("index.html", "<body>"),
        d.dir("sub", [
          d.file("bar.html", "bar"),
        ])
      ]),
      d.dir("randomdir", [
        d.file("index.html", "<body>")
      ])
    ]).create();

    pubServe(args: ["test", "web", "randomdir"]);

    schedule(() {
      // Paths in web/.
      expectWebSocketCall({
        "command": "assetIdToUrls",
        "path": "web/index.html"
      }, replyEquals: {"urls": [getServerUrl("web", "index.html")]});

      expectWebSocketCall({
        "command": "assetIdToUrls",
        "path": "web/sub/bar.html"
      }, replyEquals: {"urls": [getServerUrl("web", "sub/bar.html")]});

      // Paths in test/.
      expectWebSocketCall({
        "command": "assetIdToUrls",
        "path": "test/index.html"
      }, replyEquals: {"urls": [getServerUrl("test", "index.html")]});

      expectWebSocketCall({
        "command": "assetIdToUrls",
        "path": "test/sub/bar.html"
      }, replyEquals: {"urls": [getServerUrl("test", "sub/bar.html")]});

      // A non-default directory.
      expectWebSocketCall({
        "command": "assetIdToUrls",
        "path": "randomdir/index.html"
      }, replyEquals: {"urls": [getServerUrl("randomdir", "index.html")]});
    });

    endPubServe();
  });
}
