// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pathos/path.dart' as path;

import 'descriptor.dart' as d;
import 'test_pub.dart';

main() {
  initConfig();
  integration("includes root package's dev dependencies", () {
    d.dir('foo', [
      d.libDir('foo'),
      d.libPubspec('foo', '0.0.1')
    ]).create();

    d.dir('bar', [
      d.libDir('bar'),
      d.libPubspec('bar', '0.0.1')
    ]).create();

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dev_dependencies": {
          "foo": {"path": "../foo"},
          "bar": {"path": "../bar"},
        }
      })
    ]).create();

    schedulePub(args: ["install"],
        output: new RegExp(r"Dependencies installed!$"));

    d.dir(packagesPath, [
      d.dir("foo", [
        d.file("foo.dart", 'main() => "foo";')
      ]),
      d.dir("bar", [
        d.file("bar.dart", 'main() => "bar";')
      ])
    ]).validate();
  });

  integration("includes dev dependency's transitive dependencies", () {
    d.dir('foo', [
      d.libDir('foo'),
      d.libPubspec('foo', '0.0.1', deps: [
        {"path": "../bar"}
      ])
    ]).create();

    d.dir('bar', [
      d.libDir('bar'),
      d.libPubspec('bar', '0.0.1')
    ]).create();

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dev_dependencies": {
          "foo": {"path": "../foo"}
        }
      })
    ]).create();

    schedulePub(args: ["install"],
        output: new RegExp(r"Dependencies installed!$"));

    d.dir(packagesPath, [
      d.dir("foo", [
        d.file("foo.dart", 'main() => "foo";')
      ]),
      d.dir("bar", [
        d.file("bar.dart", 'main() => "bar";')
      ])
    ]).validate();
  });

  integration("ignores transitive dependency's dev dependencies", () {
    d.dir('foo', [
      d.libDir('foo'),
      d.pubspec({
        "name": "foo",
        "version": "0.0.1",
        "dev_dependencies": {
          "bar": {"path": "../bar"}
        }
      })
    ]).create();

    d.dir('bar', [
      d.libDir('bar'),
      d.libPubspec('bar', '0.0.1')
    ]).create();

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": "../foo"}
        }
      })
    ]).create();

    schedulePub(args: ["install"],
        output: new RegExp(r"Dependencies installed!$"));

    d.dir(packagesPath, [
      d.dir("foo", [
        d.file("foo.dart", 'main() => "foo";')
      ]),
      d.nothing("bar")
    ]).validate();
  });
}