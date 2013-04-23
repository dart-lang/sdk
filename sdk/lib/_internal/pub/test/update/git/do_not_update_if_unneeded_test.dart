// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("doesn't update one locked Git package's dependencies if it's "
      "not necessary", () {
    ensureGit();

    d.git('foo.git', [
      d.libDir('foo'),
      d.libPubspec("foo", "1.0.0", deps: [{"git": "../foo-dep.git"}])
    ]).create();

    d.git('foo-dep.git', [
      d.libDir('foo-dep'),
      d.libPubspec('foo-dep', '1.0.0')
    ]).create();

    d.appDir([{"git": "../foo.git"}]).create();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    d.dir(packagesPath, [
      d.dir('foo', [
        d.file('foo.dart', 'main() => "foo";')
      ]),
      d.dir('foo-dep', [
        d.file('foo-dep.dart', 'main() => "foo-dep";')
      ])
    ]).validate();

    d.git('foo.git', [
      d.libDir('foo', 'foo 2'),
      d.libPubspec("foo", "1.0.0", deps: [{"git": "../foo-dep.git"}])
    ]).create();

    d.git('foo-dep.git', [
      d.libDir('foo-dep', 'foo-dep 2'),
      d.libPubspec('foo-dep', '1.0.0')
    ]).commit();

    schedulePub(args: ['update', 'foo'],
        output: new RegExp(r"Dependencies updated!$"));

    d.dir(packagesPath, [
      d.dir('foo', [
        d.file('foo.dart', 'main() => "foo 2";')
      ]),
      d.dir('foo-dep', [
        d.file('foo-dep.dart', 'main() => "foo-dep";')
      ]),
    ]).validate();
  });
}
