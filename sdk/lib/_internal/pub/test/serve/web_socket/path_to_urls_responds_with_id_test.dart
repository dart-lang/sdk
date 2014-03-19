// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  initConfig();
  integration("pathToUrls includes id in response if given", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("web", [
        d.file("index.html", "<body>")
      ])
    ]).create();

    pubServe();

    expectWebSocketCall({
      "command": "pathToUrls",
      "id": "some id",
      "path": p.join("web", "index.html")
    }, replyMatches: containsPair("id", "some id"));

    endPubServe();
  });
}
