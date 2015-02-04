// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as p;

import '../../../lib/src/io.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  // TODO(rnystrom): Split into independent tests.
  initConfig();
  integration("pathToUrls converts asset ids to matching URL paths", () {
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "1.0.0"),
            d.dir("lib", [d.file("foo.dart", "foo() => null;")])]).create();

    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      }),
          d.dir(
              "test",
              [d.file("index.html", "<body>"), d.dir("sub", [d.file("bar.html", "bar"),])]),
          d.dir("lib", [d.file("app.dart", "app() => null;")]),
          d.dir(
              "web",
              [d.file("index.html", "<body>"), d.dir("sub", [d.file("bar.html", "bar"),])]),
          d.dir("randomdir", [d.file("index.html", "<body>")])]).create();

    pubServe(args: ["test", "web", "randomdir"], shouldGetFirst: true);

    // Paths in web/.
    expectWebSocketResult("pathToUrls", {
      "path": p.join("web", "index.html")
    }, {
      "urls": [getServerUrl("web", "index.html")]
    });

    expectWebSocketResult("pathToUrls", {
      "path": p.join("web", "sub", "bar.html")
    }, {
      "urls": [getServerUrl("web", "sub/bar.html")]
    });

    // Paths in test/.
    expectWebSocketResult("pathToUrls", {
      "path": p.join("test", "index.html")
    }, {
      "urls": [getServerUrl("test", "index.html")]
    });

    expectWebSocketResult("pathToUrls", {
      "path": p.join("test", "sub", "bar.html")
    }, {
      "urls": [getServerUrl("test", "sub/bar.html")]
    });

    // A non-default directory.
    expectWebSocketResult("pathToUrls", {
      "path": p.join("randomdir", "index.html")
    }, {
      "urls": [getServerUrl("randomdir", "index.html")]
    });

    // A path in lib/.
    expectWebSocketResult("pathToUrls", {
      "path": p.join("lib", "app.dart")
    }, {
      "urls": [
          getServerUrl("test", "packages/myapp/app.dart"),
          getServerUrl("web", "packages/myapp/app.dart"),
          getServerUrl("randomdir", "packages/myapp/app.dart")]
    });

    // A path to this package in packages/.
    expectWebSocketResult("pathToUrls", {
      "path": p.join("packages", "myapp", "app.dart")
    }, {
      "urls": [
          getServerUrl("test", "packages/myapp/app.dart"),
          getServerUrl("web", "packages/myapp/app.dart"),
          getServerUrl("randomdir", "packages/myapp/app.dart")]
    });

    // A path to another package in packages/.
    expectWebSocketResult("pathToUrls", {
      "path": p.join("packages", "foo", "foo.dart")
    }, {
      "urls": [
          getServerUrl("test", "packages/foo/foo.dart"),
          getServerUrl("web", "packages/foo/foo.dart"),
          getServerUrl("randomdir", "packages/foo/foo.dart")]
    });

    // A relative path to another package's lib/ directory.
    expectWebSocketResult("pathToUrls", {
      "path": p.join("..", "foo", "lib", "foo.dart")
    }, {
      "urls": [
          getServerUrl("test", "packages/foo/foo.dart"),
          getServerUrl("web", "packages/foo/foo.dart"),
          getServerUrl("randomdir", "packages/foo/foo.dart")]
    });

    // Note: Using canonicalize here because pub gets the path to the
    // entrypoint package from the working directory, which has had symlinks
    // resolve. On Mac, "/tmp" is actually a symlink to "/private/tmp", so we
    // need to accomodate that.

    // An absolute path to another package's lib/ directory.
    expectWebSocketResult("pathToUrls", {
      "path": canonicalize(p.join(sandboxDir, "foo", "lib", "foo.dart"))
    }, {
      "urls": [
          getServerUrl("test", "packages/foo/foo.dart"),
          getServerUrl("web", "packages/foo/foo.dart"),
          getServerUrl("randomdir", "packages/foo/foo.dart")]
    });

    endPubServe();
  });
}
