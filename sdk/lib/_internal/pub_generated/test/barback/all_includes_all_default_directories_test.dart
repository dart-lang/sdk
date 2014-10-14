// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../serve/utils.dart';
import '../test_pub.dart';

main() {
  initConfig();

  setUp(() {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir('benchmark', [d.file('file.txt', 'benchmark')]),
            d.dir('bin', [d.file('file.txt', 'bin')]),
            d.dir('example', [d.file('file.txt', 'example')]),
            d.dir('test', [d.file('file.txt', 'test')]),
            d.dir('web', [d.file('file.txt', 'web')]),
            d.dir('unknown', [d.file('file.txt', 'unknown')])]).create();
  });

  integration("build --all finds assets in default source directories", () {
    schedulePub(
        args: ["build", "--all"],
        output: new RegExp(r'Built 5 files to "build".'));

    d.dir(
        appPath,
        [
            d.dir(
                'build',
                [
                    d.dir('benchmark', [d.file('file.txt', 'benchmark')]),
                    d.dir('bin', [d.file('file.txt', 'bin')]),
                    d.dir('example', [d.file('file.txt', 'example')]),
                    d.dir('test', [d.file('file.txt', 'test')]),
                    d.dir('web', [d.file('file.txt', 'web')]),
                    // Only includes default source directories.
        d.nothing('unknown')])]).validate();
  });

  integration("serve --all finds assets in default source directories", () {
    pubServe(args: ["--all"]);

    requestShouldSucceed("file.txt", "benchmark", root: "benchmark");
    requestShouldSucceed("file.txt", "bin", root: "bin");
    requestShouldSucceed("file.txt", "example", root: "example");
    requestShouldSucceed("file.txt", "test", root: "test");
    requestShouldSucceed("file.txt", "web", root: "web");

    expectNotServed("unknown");

    endPubServe();
  });
}
