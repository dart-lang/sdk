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
  integration("converts asset ids to matching URL paths", () {
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

    webSocketShouldReply({
      "command": "assetToUrl",
      "package": "myapp", "path": "web/sub/bar.html"
    }, equals({"path": "/sub/bar.html"}));

    webSocketShouldReply({
      "command": "assetToUrl",
      "package": "myapp", "path": "lib/myapp.dart"
    }, equals({"path": "/packages/myapp/myapp.dart"}));

    webSocketShouldReply({
      "command": "assetToUrl",
      "package": "myapp", "path": "web/index.html"
    }, equals({"path": "/index.html"}));

    webSocketShouldReply({
      "command": "assetToUrl",
      "package": "foo",
      "path": "lib/foo.dart"
    }, equals({"path": "/packages/foo/foo.dart"}));

    webSocketShouldReply({
      "command": "assetToUrl",
      "package": "foo",
      "path": "asset/foo.txt"
    }, equals({"path": "/assets/foo/foo.txt"}));

    webSocketShouldReply({
      "command": "assetToUrl",
      "package": "foo",
      "path": "asset/sub/bar.txt"
    }, equals({"path": "/assets/foo/sub/bar.txt"}));

    endPubServe();
  });
}
