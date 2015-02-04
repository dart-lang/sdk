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
  setUp(() {
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "0.0.1"),
            d.dir("lib", [d.file("foo.dart", "foo")])]).create();

    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      }),
          d.dir("lib", [d.file("myapp.dart", "myapp"),]),
          d.dir(
              "test",
              [d.file("index.html", "<body>"), d.dir("sub", [d.file("bar.html", "bar"),])]),
          d.dir(
              "web",
              [
                  d.file("index.html", "<body>"),
                  d.dir("sub", [d.file("bar.html", "bar"),])])]).create();
  });

  integration("converts URLs to matching asset ids in web/", () {
    pubServe(shouldGetFirst: true);
    expectWebSocketResult("urlToAssetId", {
      "url": getServerUrl("web", "index.html")
    }, {
      "package": "myapp",
      "path": "web/index.html"
    });
    endPubServe();
  });

  integration(
      "converts URLs to matching asset ids in subdirectories of web/",
      () {
    pubServe(shouldGetFirst: true);
    expectWebSocketResult("urlToAssetId", {
      "url": getServerUrl("web", "sub/bar.html")
    }, {
      "package": "myapp",
      "path": "web/sub/bar.html"
    });
    endPubServe();
  });

  integration("converts URLs to matching asset ids in test/", () {
    pubServe(shouldGetFirst: true);
    expectWebSocketResult("urlToAssetId", {
      "url": getServerUrl("test", "index.html")
    }, {
      "package": "myapp",
      "path": "test/index.html"
    });
    endPubServe();
  });

  integration(
      "converts URLs to matching asset ids in subdirectories of test/",
      () {
    pubServe(shouldGetFirst: true);
    expectWebSocketResult("urlToAssetId", {
      "url": getServerUrl("test", "sub/bar.html")
    }, {
      "package": "myapp",
      "path": "test/sub/bar.html"
    });
    endPubServe();
  });

  integration(
      "converts URLs to matching asset ids in the entrypoint's lib/",
      () {
    // Path in root package's lib/.
    pubServe(shouldGetFirst: true);
    expectWebSocketResult("urlToAssetId", {
      "url": getServerUrl("web", "packages/myapp/myapp.dart")
    }, {
      "package": "myapp",
      "path": "lib/myapp.dart"
    });
    endPubServe();
  });

  integration("converts URLs to matching asset ids in a dependency's lib/", () {
    // Path in lib/.
    pubServe(shouldGetFirst: true);
    expectWebSocketResult("urlToAssetId", {
      "url": getServerUrl("web", "packages/foo/foo.dart")
    }, {
      "package": "foo",
      "path": "lib/foo.dart"
    });
    endPubServe();
  });
}
