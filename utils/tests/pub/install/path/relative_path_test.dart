// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE d.file.

import 'package:pathos/path.dart' as path;

import '../../../../pub/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("can use relative path", () {
    d.dir("foo", [
      d.libDir("foo"),
      d.libPubspec("foo", "0.0.1")
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
      ])
    ]).validate();
  });

  integration("path is relative to containing d.pubspec", () {
    d.dir("relative", [
      d.dir("foo", [
        d.libDir("foo"),
        d.libPubspec("foo", "0.0.1", deps: [
          {"path": "../bar"}
        ])
      ]),
      d.dir("bar", [
        d.libDir("bar"),
        d.libPubspec("bar", "0.0.1")
      ])
    ]).create();

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": "../relative/foo"}
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
}
