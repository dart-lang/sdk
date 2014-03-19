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
  // TODO(rnystrom): Split into independent tests.
  initConfig();
  integration("pathToUrls converts asset ids to matching URL paths", () {
    d.dir("foo", [
      d.libPubspec("foo", "1.0.0"),
      d.dir("lib", [
        d.file("foo.dart", "foo() => null;")
      ]),
      d.dir("asset", [
        d.file("foo.txt", "foo")
      ]),
    ]).create();

    d.dir(appPath, [
      d.appPubspec({"foo": {"path": "../foo"}}),
      d.dir("test", [
        d.file("index.html", "<body>"),
        d.dir("sub", [
          d.file("bar.html", "bar"),
        ])
      ]),
      d.dir("lib", [
        d.file("app.dart", "app() => null;")
      ]),
      d.dir("asset", [
        d.file("app.txt", "app")
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

    pubServe(args: ["test", "web", "randomdir"], shouldGetFirst: true);

    // Paths in web/.
    expectWebSocketCall({
      "command": "pathToUrls",
      "path": p.join("web", "index.html")
    }, replyEquals: {"urls": [getServerUrl("web", "index.html")]});

    expectWebSocketCall({
      "command": "pathToUrls",
      "path": p.join("web", "sub", "bar.html")
    }, replyEquals: {"urls": [getServerUrl("web", "sub/bar.html")]});

    // Paths in test/.
    expectWebSocketCall({
      "command": "pathToUrls",
      "path": p.join("test", "index.html")
    }, replyEquals: {"urls": [getServerUrl("test", "index.html")]});

    expectWebSocketCall({
      "command": "pathToUrls",
      "path": p.join("test", "sub", "bar.html")
    }, replyEquals: {"urls": [getServerUrl("test", "sub/bar.html")]});

    // A non-default directory.
    expectWebSocketCall({
      "command": "pathToUrls",
      "path": p.join("randomdir", "index.html")
    }, replyEquals: {"urls": [getServerUrl("randomdir", "index.html")]});

    // A path in lib/.
    expectWebSocketCall({
      "command": "pathToUrls",
      "path": p.join("lib", "app.dart")
    }, replyEquals: {"urls": [
      getServerUrl("test", "packages/myapp/app.dart"),
      getServerUrl("web", "packages/myapp/app.dart"),
      getServerUrl("randomdir", "packages/myapp/app.dart")
    ]});

    // A path in asset/.
    expectWebSocketCall({
      "command": "pathToUrls",
      "path": p.join("asset", "app.txt")
    }, replyEquals: {"urls": [
      getServerUrl("test", "assets/myapp/app.txt"),
      getServerUrl("web", "assets/myapp/app.txt"),
      getServerUrl("randomdir", "assets/myapp/app.txt")
    ]});

    // A path to this package in packages/.
    expectWebSocketCall({
      "command": "pathToUrls",
      "path": p.join("packages", "myapp", "app.dart")
    }, replyEquals: {"urls": [
      getServerUrl("test", "packages/myapp/app.dart"),
      getServerUrl("web", "packages/myapp/app.dart"),
      getServerUrl("randomdir", "packages/myapp/app.dart")
    ]});

    // A path to another package in packages/.
    expectWebSocketCall({
      "command": "pathToUrls",
      "path": p.join("packages", "foo", "foo.dart")
    }, replyEquals: {"urls": [
      getServerUrl("test", "packages/foo/foo.dart"),
      getServerUrl("web", "packages/foo/foo.dart"),
      getServerUrl("randomdir", "packages/foo/foo.dart")
    ]});

    // A relative path to another package's lib/ directory.
    expectWebSocketCall({
      "command": "pathToUrls",
      "path": p.join("..", "foo", "lib", "foo.dart")
    }, replyEquals: {"urls": [
      getServerUrl("test", "packages/foo/foo.dart"),
      getServerUrl("web", "packages/foo/foo.dart"),
      getServerUrl("randomdir", "packages/foo/foo.dart")
    ]});

    // An absolute path to another package's lib/ directory.
    expectWebSocketCall({
      "command": "pathToUrls",
      "path": p.absolute(sandboxDir, "foo", "lib", "foo.dart")
    }, replyEquals: {"urls": [
      getServerUrl("test", "packages/foo/foo.dart"),
      getServerUrl("web", "packages/foo/foo.dart"),
      getServerUrl("randomdir", "packages/foo/foo.dart")
    ]});

    // A relative path to another package's asset/ directory.
    expectWebSocketCall({
      "command": "pathToUrls",
      "path": p.join("..", "foo", "asset", "foo.dart")
    }, replyEquals: {"urls": [
      getServerUrl("test", "assets/foo/foo.dart"),
      getServerUrl("web", "assets/foo/foo.dart"),
      getServerUrl("randomdir", "assets/foo/foo.dart")
    ]});

    // An absolute path to another package's asset/ directory.
    expectWebSocketCall({
      "command": "pathToUrls",
      "path": p.absolute(sandboxDir, "foo", "asset", "foo.dart")
    }, replyEquals: {"urls": [
      getServerUrl("test", "assets/foo/foo.dart"),
      getServerUrl("web", "assets/foo/foo.dart"),
      getServerUrl("randomdir", "assets/foo/foo.dart")
    ]});

    endPubServe();
  });
}
