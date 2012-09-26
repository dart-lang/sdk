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
        output: const RegExp(r"Dependencies installed!$"));

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
        output: const RegExp(r"Dependencies updated!$"));

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

  test("updates Git packages to an incompatible pubspec", () {
    ensureGit();

    git('foo.git', [
      libDir('foo'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    git('foo.git', [
      libDir('zoo'),
      libPubspec('zoo', '1.0.0')
    ]).scheduleCommit();

    schedulePub(args: ['update'],
        error: const RegExp(r'The name you specified for your dependency, '
            r'"foo", doesn' "'" r't match the name "zoo" in its pubspec.'),
        exitCode: 1);

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    run();
  });

  solo_test("updates Git packages to a nonexistent pubspec", () {
    ensureGit();

    var repo = git('foo.git', [
      libDir('foo'),
      libPubspec('foo', '1.0.0')
    ]);
    repo.scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    repo.scheduleGit(['rm', 'pubspec.yaml']);
    repo.scheduleGit(['commit', '-m', 'delete']);

    schedulePub(args: ['update'],
        error: const RegExp(r'Package "foo" doesn' "'" r't have a '
            r'pubspec.yaml file.'),
        exitCode: 1);

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
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
          output: const RegExp(r"Dependencies installed!$"));

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
          output: const RegExp(r"Dependencies updated!$"));

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
          output: const RegExp(r"Dependencies installed!$"));

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
          output: const RegExp(r"Dependencies updated!$"));

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
