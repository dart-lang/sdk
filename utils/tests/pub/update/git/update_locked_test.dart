// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("updates locked Git packages", () {
    ensureGit();

    d.git('foo.git', [
      d.libDir('foo'),
      d.libPubspec('foo', '1.0.0')
    ]).create();

    d.git('bar.git', [
      d.libDir('bar'),
      d.libPubspec('bar', '1.0.0')
    ]).create();

    d.appDir([{"git": "../foo.git"}, {"git": "../bar.git"}]).create();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    d.dir(packagesPath, [
      d.dir('foo', [
        d.file('foo.dart', 'main() => "foo";')
      ]),
      d.dir('bar', [
        d.file('bar.dart', 'main() => "bar";')
      ])
    ]).validate();

    d.git('foo.git', [
      d.libDir('foo', 'foo 2'),
      d.libPubspec('foo', '1.0.0')
    ]).commit();

    d.git('bar.git', [
      d.libDir('bar', 'bar 2'),
      d.libPubspec('bar', '1.0.0')
    ]).commit();

    schedulePub(args: ['update'],
        output: new RegExp(r"Dependencies updated!$"));

    d.dir(packagesPath, [
      d.dir('foo', [
        d.file('foo.dart', 'main() => "foo 2";')
      ]),
      d.dir('bar', [
        d.file('bar.dart', 'main() => "bar 2";')
      ])
    ]).validate();
  });
}
