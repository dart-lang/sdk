// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  // TODO(rnystrom): Split into independent tests.
  initConfig();
  integration("assetIdToUrls handles files in the top-level directory", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.file("top.txt", "top"),
      d.dir("web", [
        d.file("index.html", "<body>"),
        d.dir("sub", [
          d.file("bar.html", "bar"),
        ])
      ])
    ]).create();

    pubServe(args: [".", "web", path.join("web", "sub")]);

    schedule(() {
      expectWebSocketCall({
        "command": "assetIdToUrls",
        "path": "top.txt"
      }, replyEquals: {
        "urls": [
          getServerUrl(".", "top.txt")
        ]
      });

      expectWebSocketCall({
        "command": "assetIdToUrls",
        "path": "web/sub/bar.html"
      }, replyEquals: {
        "urls": [
          getServerUrl("web", "sub/bar.html"),
          getServerUrl(".", "web/sub/bar.html"),
          getServerUrl(path.join("web", "sub"), "bar.html")
        ]
      });
    });

    endPubServe();
  });
}
