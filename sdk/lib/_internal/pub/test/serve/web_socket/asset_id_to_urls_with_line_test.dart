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
  integration("assetIdToUrls provides output line if given source", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("web", [
        d.file("main.dart", "main"),
      ])
    ]).create();

    pubServe();

    schedule(() {
      expectWebSocketCall({
        "command": "assetIdToUrls",
        "path": "web/main.dart",
        "line": 12345
      }, replyEquals: {
        "urls": [getServerUrl("web", "main.dart")],
        "line": 12345
      });
    });

    endPubServe();
  });
}
