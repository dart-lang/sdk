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
  integration("includes id in response if given with command", () {
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
      expectWebSocketCall({
        "command": "assetIdToUrls",
        "id": "some id",
        "path": "web/index.html"
      }, replyMatches: containsPair("id", "some id"));

      expectWebSocketCall({
        "command": "urlToAssetId",
        "id": 12345,
        "url": getServerUrl("web", "index.html")
      }, replyMatches: containsPair("id", 12345));
    });

    endPubServe();
  });
}
