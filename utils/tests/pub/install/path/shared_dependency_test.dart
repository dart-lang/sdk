// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE d.file.

import 'package:pathos/path.dart' as path;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("shared dependency with same path", () {
    d.dir("shared", [
      d.libDir("shared"),
      d.libPubspec("shared", "0.0.1")
    ]).create();

    d.dir("foo", [
      d.libDir("foo"),
      d.libPubspec("foo", "0.0.1", deps: [
        {"path": "../shared"}
      ])
    ]).create();

    d.dir("bar", [
      d.libDir("bar"),
      d.libPubspec("bar", "0.0.1", deps: [
        {"path": "../shared"}
      ])
    ]).create();

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": "../foo"},
          "bar": {"path": "../bar"}
        }
      })
    ]).create();

    schedulePub(args: ["install"],
        output: new RegExp(r"Dependencies installed!$"));

    d.dir(packagesPath, [
      d.dir("foo", [d.file("foo.dart", 'main() => "foo";')]),
      d.dir("bar", [d.file("bar.dart", 'main() => "bar";')]),
      d.dir("shared", [d.file("shared.dart", 'main() => "shared";')])
    ]).validate();
  });

  integration("shared dependency with paths that normalize the same", () {
    d.dir("shared", [
      d.libDir("shared"),
      d.libPubspec("shared", "0.0.1")
    ]).create();

    d.dir("foo", [
      d.libDir("foo"),
      d.libPubspec("foo", "0.0.1", deps: [
        {"path": "../shared"}
      ])
    ]).create();

    d.dir("bar", [
      d.libDir("bar"),
      d.libPubspec("bar", "0.0.1", deps: [
        {"path": "../././shared"}
      ])
    ]).create();

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": "../foo"},
          "bar": {"path": "../bar"}
        }
      })
    ]).create();

    schedulePub(args: ["install"],
        output: new RegExp(r"Dependencies installed!$"));

    d.dir(packagesPath, [
      d.dir("foo", [d.file("foo.dart", 'main() => "foo";')]),
      d.dir("bar", [d.file("bar.dart", 'main() => "bar";')]),
      d.dir("shared", [d.file("shared.dart", 'main() => "shared";')])
    ]).validate();
  });

  integration("shared dependency with absolute and relative path", () {
    d.dir("shared", [
      d.libDir("shared"),
      d.libPubspec("shared", "0.0.1")
    ]).create();

    d.dir("foo", [
      d.libDir("foo"),
      d.libPubspec("foo", "0.0.1", deps: [
        {"path": "../shared"}
      ])
    ]).create();

    d.dir("bar", [
      d.libDir("bar"),
      d.libPubspec("bar", "0.0.1", deps: [
        {"path": path.join(sandboxDir, "shared")}
      ])
    ]).create();

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": "../foo"},
          "bar": {"path": "../bar"}
        }
      })
    ]).create();

    schedulePub(args: ["install"],
        output: new RegExp(r"Dependencies installed!$"));

    d.dir(packagesPath, [
      d.dir("foo", [d.file("foo.dart", 'main() => "foo";')]),
      d.dir("bar", [d.file("bar.dart", 'main() => "bar";')]),
      d.dir("shared", [d.file("shared.dart", 'main() => "shared";')])
    ]).validate();
  });
}