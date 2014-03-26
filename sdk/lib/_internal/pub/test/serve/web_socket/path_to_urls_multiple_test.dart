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
  integration("pathToUrls returns multiple urls if servers overlap", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("test", [
        d.file("index.html", "<body>")
      ]),
      d.dir("web", [
        d.file("index.html", "<body>"),
        d.dir("sub", [
          d.file("bar.html", "bar"),
        ])
      ])
    ]).create();

    pubServe(args: ["web", path.join("web", "sub"), "test"]);

    expectWebSocketResult("pathToUrls", {
      "path": path.join("web", "index.html")
    }, {
      "urls": [getServerUrl("web", "index.html")]
    });

    expectWebSocketResult("pathToUrls", {
      "path": path.join("web", "sub", "bar.html")
    }, {
      "urls": [
        getServerUrl("web", "sub/bar.html"),
        getServerUrl(path.join("web", "sub"), "bar.html")
      ]
    });

    endPubServe();
  });
}
