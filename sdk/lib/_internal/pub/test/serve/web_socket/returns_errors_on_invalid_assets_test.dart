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
  integration("returns errors on invalid assets", () {
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
      "package": "myapp", "path": "top.txt"
    }, equals({"error":  "Can not serve assets from top-level directory."}));

    webSocketShouldReply({
      "command": "assetToUrl",
      "package": "foo", "path": "web/foo.dart"
    }, equals({
      "error": 'Cannot access "web" directory of non-root packages.'
    }));

    webSocketShouldReply({
      "command": "assetToUrl",
      "package": "myapp", "path": "blah/index.html"
    }, equals({"error": 'Cannot access assets from "blah".'}));

    endPubServe();
  });
}
