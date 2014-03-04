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
  integration("urlToAssetId errors on bad inputs", () {
    d.dir(appPath, [
      d.appPubspec()
    ]).create();

    pubServe();

    // Bad arguments.
    expectWebSocketCall({
      "command": "urlToAssetId"
    }, replyEquals: {
      "code": "BAD_ARGUMENT",
      "error": 'Missing "url" argument.'
    });

    expectWebSocketCall({
      "command": "urlToAssetId",
      "url": 123
    }, replyEquals: {
      "code": "BAD_ARGUMENT",
      "error": '"url" must be a string. Got 123.'
    });

    expectWebSocketCall({
      "command": "urlToAssetId",
      "url": "http://localhost:notnum/"
    }, replyEquals: {
      "code": "BAD_ARGUMENT",
      "error": '"http://localhost:notnum/" is not a valid URL.'
    });

    // Unknown domain.
    expectWebSocketCall({
      "command": "urlToAssetId",
      "url": "http://example.com:80/index.html"
    }, replyEquals: {
      "code": "NOT_SERVED",
      "error": '"example.com:80" is not being served by pub.'
    });

    // Unknown port.
    expectWebSocketCall({
      "command": "urlToAssetId",
      "url": "http://localhost:80/index.html"
    }, replyEquals: {
      "code": "NOT_SERVED",
      "error": '"localhost:80" is not being served by pub.'
    });

    schedule(() {
      expectWebSocketCall({
        "command": "urlToAssetId",
        "url": getServerUrl("web", "index.html"),
        "line": 12.34
      }, replyEquals: {
        "code": "BAD_ARGUMENT",
        "error": '"line" must be an integer. Got 12.34.'
      });
    });

    endPubServe();
  });
}
