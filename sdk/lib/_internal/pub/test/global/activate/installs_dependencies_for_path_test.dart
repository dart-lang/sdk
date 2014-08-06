// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_stream.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('activating a path package installs dependencies', () {
    servePackages([
      packageMap("bar", "1.0.0", {"baz": "any"}),
      packageMap("baz", "2.0.0")
    ]);

    d.dir("foo", [
      d.libPubspec("foo", "0.0.0", deps: {
        "bar": "any"
      }),
      d.dir("bin", [
        d.file("foo.dart", "main() => print('ok');")
      ])
    ]).create();

    var pub = startPub(args: ["global", "activate", "-spath", "../foo"]);
    pub.stdout.expect(consumeThrough("Resolving dependencies..."));
    pub.stdout.expect(consumeThrough("Downloading bar 1.0.0..."));
    pub.stdout.expect(consumeThrough("Downloading baz 2.0.0..."));
    pub.stdout.expect(consumeThrough(
        startsWith("Activated foo 0.0.0 at path")));
    pub.shouldExit();

    // Puts the lockfile in the linked package itself.
    d.dir("foo", [
      d.matcherFile("pubspec.lock", allOf([
        contains("bar"), contains("1.0.0"),
        contains("baz"), contains("2.0.0")
      ]))
    ]).validate();
  });
}
