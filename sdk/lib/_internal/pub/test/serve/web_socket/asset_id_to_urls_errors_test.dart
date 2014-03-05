// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  // TODO(rnystrom): Split into independent tests.
  initConfig();
  integration("assetIdToUrls errors on bad inputs", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.file("top-level.txt", "top-level"),
      d.dir("asset", [
        d.file("foo.txt", "foo"),
      ]),
      d.dir("bin", [
        d.file("foo.txt", "foo"),
      ]),
      d.dir("lib", [
        d.file("myapp.dart", "myapp"),
      ])
    ]).create();

    pubServe();

    // Bad arguments.
    expectWebSocketCall({
      "command": "assetIdToUrls"
    }, replyEquals: {
      "code": "BAD_ARGUMENT",
      "error": 'Missing "path" argument.'
    });

    expectWebSocketCall({
      "command": "assetIdToUrls",
      "path": 123
    }, replyEquals: {
      "code": "BAD_ARGUMENT",
      "error": '"path" must be a string. Got 123.'
    });

    expectWebSocketCall({
      "command": "assetIdToUrls",
      "path": "/absolute.txt"
    }, replyEquals: {
      "code": "BAD_ARGUMENT",
      "error": '"path" must be a relative path. Got "/absolute.txt".'
    });

    expectWebSocketCall({
      "command": "assetIdToUrls",
      "path": "a/../../bad.txt"
    }, replyEquals: {
      "code": "BAD_ARGUMENT",
      "error":
          '"path" cannot reach out of its containing directory. '
          'Got "a/../../bad.txt".'
    });

    expectWebSocketCall({
      "command": "assetIdToUrls",
      "path": "main.dart",
      "line": 12.34
    }, replyEquals: {
      "code": "BAD_ARGUMENT",
      "error": '"line" must be an integer. Got 12.34.'
    });

    // Unserved directories.
    expectWebSocketCall({
      "command": "assetIdToUrls",
      "path": "bin/foo.txt"
    }, replyEquals: {
      "code": "NOT_SERVED",
      "error": 'Asset path "bin/foo.txt" is not currently being served.'
    });

    expectWebSocketCall({
      "command": "assetIdToUrls",
      "path": "lib/myapp.dart"
    }, replyEquals: {
      "code": "NOT_SERVED",
      "error": 'Asset path "lib/myapp.dart" is not currently being served.'
    });

    expectWebSocketCall({
      "command": "assetIdToUrls",
      "path": "asset/myapp.dart"
    }, replyEquals: {
      "code": "NOT_SERVED",
      "error": 'Asset path "asset/myapp.dart" is not currently being served.'
    });

    expectWebSocketCall({
      "command": "assetIdToUrls",
      "path": "nope/foo.txt"
    }, replyEquals: {
      "code": "NOT_SERVED",
      "error": 'Asset path "nope/foo.txt" is not currently being served.'
    });

    endPubServe();
  });
}
