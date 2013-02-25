// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../../../pkg/pathos/lib/path.dart' as path;

import '../../test_pub.dart';

main() {
  initConfig();
  integration("shared dependency with same path", () {
    dir("shared", [
      libDir("shared"),
      libPubspec("shared", "0.0.1")
    ]).scheduleCreate();

    dir("foo", [
      libDir("foo"),
      libPubspec("foo", "0.0.1", deps: [
        {"path": "../shared"}
      ])
    ]).scheduleCreate();

    dir("bar", [
      libDir("bar"),
      libPubspec("bar", "0.0.1", deps: [
        {"path": "../shared"}
      ])
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": "../foo"},
          "bar": {"path": "../bar"}
        }
      })
    ]).scheduleCreate();

    schedulePub(args: ["install"],
        output: new RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir("foo", [file("foo.dart", 'main() => "foo";')]),
      dir("bar", [file("bar.dart", 'main() => "bar";')]),
      dir("shared", [file("shared.dart", 'main() => "shared";')])
    ]).scheduleValidate();
  });

  integration("shared dependency with paths that normalize the same", () {
    dir("shared", [
      libDir("shared"),
      libPubspec("shared", "0.0.1")
    ]).scheduleCreate();

    dir("foo", [
      libDir("foo"),
      libPubspec("foo", "0.0.1", deps: [
        {"path": "../shared"}
      ])
    ]).scheduleCreate();

    dir("bar", [
      libDir("bar"),
      libPubspec("bar", "0.0.1", deps: [
        {"path": "../././shared"}
      ])
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": "../foo"},
          "bar": {"path": "../bar"}
        }
      })
    ]).scheduleCreate();

    schedulePub(args: ["install"],
        output: new RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir("foo", [file("foo.dart", 'main() => "foo";')]),
      dir("bar", [file("bar.dart", 'main() => "bar";')]),
      dir("shared", [file("shared.dart", 'main() => "shared";')])
    ]).scheduleValidate();
  });

  integration("shared dependency with absolute and relative path", () {
    dir("shared", [
      libDir("shared"),
      libPubspec("shared", "0.0.1")
    ]).scheduleCreate();

    dir("foo", [
      libDir("foo"),
      libPubspec("foo", "0.0.1", deps: [
        {"path": "../shared"}
      ])
    ]).scheduleCreate();

    dir("bar", [
      libDir("bar"),
      libPubspec("bar", "0.0.1", deps: [
        {"path": path.join(sandboxDir, "shared")}
      ])
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": "../foo"},
          "bar": {"path": "../bar"}
        }
      })
    ]).scheduleCreate();

    schedulePub(args: ["install"],
        output: new RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir("foo", [file("foo.dart", 'main() => "foo";')]),
      dir("bar", [file("bar.dart", 'main() => "bar";')]),
      dir("shared", [file("shared.dart", 'main() => "shared";')])
    ]).scheduleValidate();
  });

  integration("shared dependency with symlink", () {
    dir("shared", [
      libDir("shared"),
      libPubspec("shared", "0.0.1")
    ]).scheduleCreate();

    dir("foo", [
      libDir("foo"),
      libPubspec("foo", "0.0.1", deps: [
        {"path": "../shared"}
      ])
    ]).scheduleCreate();

    dir("bar", [
      libDir("bar"),
      libPubspec("bar", "0.0.1", deps: [
        {"path": "../link/shared"}
      ])
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": "../foo"},
          "bar": {"path": "../bar"}
        }
      })
    ]).scheduleCreate();

    dir("link").scheduleCreate();
    scheduleSymlink("shared", path.join("link", "shared"));

    schedulePub(args: ["install"],
        output: new RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir("foo", [file("foo.dart", 'main() => "foo";')]),
      dir("bar", [file("bar.dart", 'main() => "bar";')]),
      dir("shared", [file("shared.dart", 'main() => "shared";')])
    ]).scheduleValidate();
  });
}