// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';
import 'dart:json' as json;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("does not install if the locked version of a dependency is "
      "allowed by the pubspec's constraint", () {
    d.dir("foo", [
      d.libPubspec("foo", "0.0.1"),
      d.libDir("foo")
    ]).create();

    // Install to get "foo" into the lock file.
    d.dir(appPath, [
      d.appPubspec({
        "foo": {
          "path": "../foo",
          "version": ">=0.0.1"
        },
      })
    ]).create();
    pubInstall();

    // Change the version.
    d.dir(appPath, [
      d.appPubspec({
        "foo": {
          "path": "../foo",
          "version": "<2.0.0"
        },
      })
    ]).create();

    startPubServe(shouldInstallFirst: false);
    requestShouldSucceed("packages/foo/foo.dart", 'main() => "foo";');
    endPubServe();
  });
}
