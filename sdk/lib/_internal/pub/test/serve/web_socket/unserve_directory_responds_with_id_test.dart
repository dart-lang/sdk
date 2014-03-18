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
  integration("unserveDirectory includes id in response if given", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("example", [
        d.file("index.html", "<body>")
      ]),
      d.dir("web", [
        d.file("index.html", "<body>")
      ])
    ]).create();

    // TODO(rnystrom): "example" is in here so that that's the port the web
    // socket is bound to. That way, when we unserve "web", we don't close the
    // web socket connection itself.
    // Remove this when #16957 is fixed.
    pubServe(args: ["example", "web"]);

    expectWebSocketCall({
      "command": "unserveDirectory",
      "id": 12345,
      "path": "web"
    }, replyMatches: containsPair("id", 12345));

    endPubServe();
  });
}
