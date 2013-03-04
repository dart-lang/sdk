// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../../../pkg/pathos/lib/path.dart' as path;

import '../../../../pub/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("can use relative path", () {
    dir("foo", [
      libDir("foo"),
      libPubspec("foo", "0.0.1")
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
      ])
    ]).scheduleValidate();
  });

  integration("path is relative to containing pubspec", () {
    dir("relative", [
      dir("foo", [
        libDir("foo"),
        libPubspec("foo", "0.0.1", deps: [
          {"path": "../bar"}
        ])
      ]),
      dir("bar", [
        libDir("bar"),
        libPubspec("bar", "0.0.1")
      ])
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": "../relative/foo"}
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
}
