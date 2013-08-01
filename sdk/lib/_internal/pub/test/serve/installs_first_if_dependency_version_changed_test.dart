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
  integration("installs first if a dependency's version doesn't match the one "
      "in the lock file", () {
    d.dir("foo", [
      d.libPubspec("foo", "0.0.1"),
      d.libDir("foo")
    ]).create();

    d.appDir({
      "foo": {
        "path": "../foo",
        "version": "0.0.1"
      }
    }).create();

    pubInstall();

    // Change the version in the pubspec and package.
    d.appDir({
      "foo": {
        "path": "../foo",
        "version": "0.0.2"
      }
    }).create();

    d.dir("foo", [
      d.libPubspec("foo", "0.0.2"),
      d.libDir("foo")
    ]).create();

    startPubServe(shouldInstallFirst: true);
    requestShouldSucceed("packages/foo/foo.dart", 'main() => "foo";');
    endPubServe();
  });
}
