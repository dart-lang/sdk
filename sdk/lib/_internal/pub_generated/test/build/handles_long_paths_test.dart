// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import 'package:path/path.dart' as path;

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  // This is a regression test for dartbug.com/14442.
  //
  // If you have a long chain of path dependencies with long relative paths,
  // you can end up with a combined path that is longer than the OS can handle.
  // For example, the path that revealed this bug was:
  //
  // C:\jenkins-slave\workspace\mSEE-Dev\ozone\dart\portfolio-manager\src\main\
  // portfolio-manager\..\..\..\..\portfolio-common\src\main\portfolio-common\
  // ../../../../dart-visualization/src/main/dart-visualization\lib\src\vega\
  // data\transform\visual
  //
  // This test ensures that we're normalizing at some point before we throw the
  // path at the OS to choke on.

  integration("handles long relative paths", () {
    // Dart2js can take a long time to compile dart code, so we increase the
    // timeout to cope with that.
    currentSchedule.timeout *= 3;

    d.dir(
        "some_long_dependency_name",
        [
            d.libPubspec("foo", "0.0.1"),
            d.dir("lib", [d.file("foo.txt", "foo")])]).create();

    // Build a 2,800 character (non-canonicalized) path.
    var longPath = "";
    for (var i = 0; i < 100; i++) {
      longPath = path.join(longPath, "..", "some_long_dependency_name");
    }

    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": longPath
        }
      }), d.dir("web", [d.file("index.html", "html"),])]).create();

    schedulePub(
        args: ["build"],
        output: new RegExp(r'Built 2 files to "build".'));

    d.dir(
        appPath,
        [
            d.dir(
                'build',
                [
                    d.dir(
                        'web',
                        [
                            d.file("index.html", "html"),
                            d.dir('packages', [d.dir('foo', [d.file('foo.txt', 'foo')])])])])]).validate();
  });
}
