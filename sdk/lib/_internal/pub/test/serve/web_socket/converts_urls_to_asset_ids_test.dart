// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
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
      d.dir("web", [
        d.file("index.html", "<body>"),
        d.dir("sub", [
          d.file("bar.html", "bar"),
        ])
      ])
    ]).create();

    startPubServe(shouldGetFirst: true);

    webSocketShouldReply(
        {"command": "urlToAsset", "path": "sub/bar.html"},
        equals({"package": "myapp", "path": "web/sub/bar.html"}));

    webSocketShouldReply(
        {"command": "urlToAsset", "path": "packages/myapp/myapp.dart"},
        equals({"package": "myapp", "path": "lib/myapp.dart"}));

    webSocketShouldReply(
        {"command": "urlToAsset", "path": "index.html"},
        equals({"package": "myapp", "path": "web/index.html"}));

    webSocketShouldReply(
        {"command": "urlToAsset", "path": "packages/foo/foo.dart"},
        equals({"package": "foo", "path": "lib/foo.dart"}));

    webSocketShouldReply(
        {"command": "urlToAsset", "path": "assets/foo/foo.txt"},
        equals({"package": "foo", "path": "asset/foo.txt"}));

    webSocketShouldReply(
        {"command": "urlToAsset", "path": "assets/foo/sub/bar.txt"},
        equals({"package": "foo", "path": "asset/sub/bar.txt"}));

    endPubServe();
  });
}
