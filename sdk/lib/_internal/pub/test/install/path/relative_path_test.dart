// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE d.file.

import 'package:path/path.dart' as path;

import '../../../lib/src/exit_codes.dart' as exit_codes;
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
      d.appPubspec({
        "foo": {"path": "../foo"}
      })
    ]).create();

    pubInstall();

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
        d.libPubspec("foo", "0.0.1", deps: {
          "bar": {"path": "../bar"}
        })
      ]),
      d.dir("bar", [
        d.libDir("bar"),
        d.libPubspec("bar", "0.0.1")
      ])
    ]).create();

    d.dir(appPath, [
      d.appPubspec({
        "foo": {"path": "../relative/foo"}
      })
    ]).create();

    pubInstall();

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
