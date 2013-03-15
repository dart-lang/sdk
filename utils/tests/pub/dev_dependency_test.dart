// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../pkg/pathos/lib/path.dart' as path;

import 'test_pub.dart';

main() {
  initConfig();
  integration("includes root package's dev dependencies", () {
    dir('foo', [
      libDir('foo'),
      libPubspec('foo', '0.0.1')
    ]).scheduleCreate();

    dir('bar', [
      libDir('bar'),
      libPubspec('bar', '0.0.1')
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dev_dependencies": {
          "foo": {"path": "../foo"},
          "bar": {"path": "../bar"},
        }
      })
    ]).scheduleCreate();

    schedulePub(args: ["install"],
        output: new RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir("foo", [
        file("foo.dart", 'main() => "foo";')
      ]),
      dir("bar", [
        file("bar.dart", 'main() => "bar";')
      ])
    ]).scheduleValidate();
  });

  integration("includes dev dependency's transitive dependencies", () {
    dir('foo', [
      libDir('foo'),
      libPubspec('foo', '0.0.1', deps: [
        {"path": "../bar"}
      ])
    ]).scheduleCreate();

    dir('bar', [
      libDir('bar'),
      libPubspec('bar', '0.0.1')
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dev_dependencies": {
          "foo": {"path": "../foo"}
        }
      })
    ]).scheduleCreate();

    schedulePub(args: ["install"],
        output: new RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir("foo", [
        file("foo.dart", 'main() => "foo";')
      ]),
      dir("bar", [
        file("bar.dart", 'main() => "bar";')
      ])
    ]).scheduleValidate();
  });

  integration("ignores transitive dependency's dev dependencies", () {
    dir('foo', [
      libDir('foo'),
      pubspec({
        "name": "foo",
        "version": "0.0.1",
        "dev_dependencies": {
          "bar": {"path": "../bar"}
        }
      })
    ]).scheduleCreate();

    dir('bar', [
      libDir('bar'),
      libPubspec('bar', '0.0.1')
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": "../foo"}
        }
      })
    ]).scheduleCreate();

    schedulePub(args: ["install"],
        output: new RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir("foo", [
        file("foo.dart", 'main() => "foo";')
      ]),
      nothing("bar")
    ]).scheduleValidate();
  });
}