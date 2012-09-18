// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('pub_tests');

#import('dart:io');

#import('test_pub.dart');
#import('../../../pkg/unittest/unittest.dart');

main() {
  test("updates locked Git packages", () {
    ensureGit();

    git('foo.git', [
      libDir('foo'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCreate();

    git('bar.git', [
      libDir('bar'),
      libPubspec('bar', '1.0.0')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}, {"git": "../bar.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ]),
      dir('bar', [
        file('bar.dart', 'main() => "bar";')
      ])
    ]).scheduleValidate();

    git('foo.git', [
      libDir('foo', 'foo 2'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCommit();

    git('bar.git', [
      libDir('bar', 'bar 2'),
      libPubspec('bar', '1.0.0')
    ]).scheduleCommit();

    schedulePub(args: ['update'],
        output: const RegExp(@"Dependencies updated!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo 2";')
      ]),
      dir('bar', [
        file('bar.dart', 'main() => "bar 2";')
      ])
    ]).scheduleValidate();

    run();
  });

  group("with an argument", () {
    test("updates one locked Git package but no others", () {
      ensureGit();

      git('foo.git', [
        libDir('foo'),
        libPubspec('foo', '1.0.0')
      ]).scheduleCreate();

      git('bar.git', [
        libDir('bar'),
        libPubspec('bar', '1.0.0')
      ]).scheduleCreate();

      appDir([{"git": "../foo.git"}, {"git": "../bar.git"}]).scheduleCreate();

      schedulePub(args: ['install'],
          output: const RegExp(@"Dependencies installed!$"));

      dir(packagesPath, [
        dir('foo', [
          file('foo.dart', 'main() => "foo";')
        ]),
        dir('bar', [
          file('bar.dart', 'main() => "bar";')
        ])
      ]).scheduleValidate();

      git('foo.git', [
        libDir('foo', 'foo 2'),
        libPubspec('foo', '1.0.0')
      ]).scheduleCommit();

      git('bar.git', [
        libDir('bar', 'bar 2'),
        libPubspec('bar', '1.0.0')
      ]).scheduleCommit();

      schedulePub(args: ['update', 'foo'],
          output: const RegExp(@"Dependencies updated!$"));

      dir(packagesPath, [
        dir('foo', [
          file('foo.dart', 'main() => "foo 2";')
        ]),
        dir('bar', [
          file('bar.dart', 'main() => "bar";')
        ])
      ]).scheduleValidate();

      run();
    });

    test("doesn't update one locked Git package's dependencies if it's not "
        "necessary", () {
      ensureGit();

      git('foo.git', [
        libDir('foo'),
        libPubspec("foo", "1.0.0", [{"git": "../foo-dep.git"}])
      ]).scheduleCreate();

      git('foo-dep.git', [
        libDir('foo-dep'),
        libPubspec('foo-dep', '1.0.0')
      ]).scheduleCreate();

      appDir([{"git": "../foo.git"}]).scheduleCreate();

      schedulePub(args: ['install'],
          output: const RegExp(@"Dependencies installed!$"));

      dir(packagesPath, [
        dir('foo', [
          file('foo.dart', 'main() => "foo";')
        ]),
        dir('foo-dep', [
          file('foo-dep.dart', 'main() => "foo-dep";')
        ])
      ]).scheduleValidate();

      git('foo.git', [
        libDir('foo', 'foo 2'),
        libPubspec("foo", "1.0.0", [{"git": "../foo-dep.git"}])
      ]).scheduleCreate();

      git('foo-dep.git', [
        libDir('foo-dep', 'foo-dep 2'),
        libPubspec('foo-dep', '1.0.0')
      ]).scheduleCommit();

      schedulePub(args: ['update', 'foo'],
          output: const RegExp(@"Dependencies updated!$"));

      dir(packagesPath, [
        dir('foo', [
          file('foo.dart', 'main() => "foo 2";')
        ]),
        dir('foo-dep', [
          file('foo-dep.dart', 'main() => "foo-dep";')
        ]),
      ]).scheduleValidate();

      run();
    });
  });
}
