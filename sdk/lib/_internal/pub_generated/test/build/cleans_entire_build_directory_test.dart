// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("cleans entire build directory before a build", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir('example', [d.file('file.txt', 'example')]),
            d.dir('test', [d.file('file.txt', 'test')])]).create();

    // Make a build directory containing "example".
    schedulePub(
        args: ["build", "example"],
        output: new RegExp(r'Built 1 file to "build".'));

    // Now build again with just "test". Should wipe out "example".
    schedulePub(
        args: ["build", "test"],
        output: new RegExp(r'Built 1 file to "build".'));

    d.dir(
        appPath,
        [
            d.dir(
                'build',
                [
                    d.nothing('example'),
                    d.dir('test', [d.file('file.txt', 'test')]),])]).validate();
  });
}
