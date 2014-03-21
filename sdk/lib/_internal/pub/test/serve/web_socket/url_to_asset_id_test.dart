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
  integration("converts URLs to matching asset ids", () {
    d.dir("foo", [
      d.libPubspec("foo", "0.0.1"),
      d.dir("asset", [
        d.file("foo.txt", "foo"),
        d.dir("sub", [
          d.file("bar.txt", "bar"),
        ])
      ]),
      d.dir("lib", [
        d.file("foo.dart", "foo")
      ])
    ]).create();

    d.dir(appPath, [
      d.appPubspec({
        "foo": {"path": "../foo"}
      }),
      d.dir("lib", [
        d.file("myapp.dart", "myapp"),
      ]),
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
      ])
    ]).create();

    pubServe(shouldGetFirst: true);

    schedule(() {
      // Paths in web/.
      expectWebSocketCall({
        "command": "urlToAssetId",
        "url": getServerUrl("web", "sub/bar.html")
      }, replyEquals: {"package": "myapp", "path": "web/sub/bar.html"});

      expectWebSocketCall({
        "command": "urlToAssetId",
        "url": getServerUrl("web", "index.html")
      }, replyEquals: {"package": "myapp", "path": "web/index.html"});

      // Paths in test/.
      expectWebSocketCall({
        "command": "urlToAssetId",
        "url": getServerUrl("test", "sub/bar.html")
      }, replyEquals: {"package": "myapp", "path": "test/sub/bar.html"});

      expectWebSocketCall({
        "command": "urlToAssetId",
        "url": getServerUrl("test", "index.html")
      }, replyEquals: {"package": "myapp", "path": "test/index.html"});

      // Path in root package's lib/.
      expectWebSocketCall({
        "command": "urlToAssetId",
        "url": getServerUrl("web", "packages/myapp/myapp.dart")
      }, replyEquals: {"package": "myapp", "path": "lib/myapp.dart"});

      // Path in lib/.
      expectWebSocketCall({
        "command": "urlToAssetId",
        "url": getServerUrl("web", "packages/foo/foo.dart")
      }, replyEquals: {"package": "foo", "path": "lib/foo.dart"});

      // Paths in asset/.
      expectWebSocketCall({
        "command": "urlToAssetId",
        "url": getServerUrl("web", "assets/foo/foo.txt")
      }, replyEquals: {"package": "foo", "path": "asset/foo.txt"});

      expectWebSocketCall({
        "command": "urlToAssetId",
        "url": getServerUrl("web", "assets/foo/sub/bar.txt")
      }, replyEquals: {"package": "foo", "path": "asset/sub/bar.txt"});
    });

    endPubServe();
  });
}
