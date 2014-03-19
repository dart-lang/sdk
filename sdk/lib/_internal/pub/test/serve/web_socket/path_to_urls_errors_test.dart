// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as p;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  // TODO(rnystrom): Split into independent tests.
  initConfig();
  integration("pathToUrls errors on bad inputs", () {
    d.dir("foo", [
      d.libPubspec("foo", "1.0.0"),
      d.dir("web", [
        d.file("foo.txt", "foo")
      ])
    ]).create();

    d.dir(appPath, [
      d.appPubspec({"foo": {"path": "../foo"}}),
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

    pubServe(shouldGetFirst: true);

    // Bad arguments.
    expectWebSocketCall({
      "command": "pathToUrls"
    }, replyEquals: {
      "code": "BAD_ARGUMENT",
      "error": 'Missing "path" argument.'
    });

    expectWebSocketCall({
      "command": "pathToUrls",
      "path": 123
    }, replyEquals: {
      "code": "BAD_ARGUMENT",
      "error": '"path" must be a string. Got 123.'
    });

    expectWebSocketCall({
      "command": "pathToUrls",
      "path": "main.dart",
      "line": 12.34
    }, replyEquals: {
      "code": "BAD_ARGUMENT",
      "error": '"line" must be an integer. Got 12.34.'
    });

    // Unserved directories.
    expectNotServed(p.join('bin', 'foo.txt'));
    expectNotServed(p.join('nope', 'foo.txt'));
    expectNotServed(p.join("..", "bar", "lib", "bar.txt"));
    expectNotServed(p.join("..", "foo", "web", "foo.txt"));

    endPubServe();
  });
}

void expectNotServed(String path) {
  expectWebSocketCall({
    "command": "pathToUrls",
    "path": path
  }, replyEquals: {
    "code": "NOT_SERVED",
    "error": 'Asset path "$path" is not currently being served.'
  });
}
