// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('pub_tests');

#import('dart:io');

#import('test_pub.dart');
#import('../../../pkg/unittest/unittest.dart');

main() {
  test('checks out a package from Git', () {
    ensureGit();

    git('foo.git', [
      file('foo.dart', 'main() => "foo";')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(cachePath, [
      dir('git', [
        dir('cache', [gitPackageCacheDir('foo')]),
        gitPackageCacheDir('foo')
      ])
    ]).scheduleValidate();

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    run();
  });

  test('checks out packages transitively from Git', () {
    ensureGit();

    git('foo.git', [
      file('foo.dart', 'main() => "foo";'),
      appPubspec([{"git": "../bar.git"}])
    ]).scheduleCreate();

    git('bar.git', [
      file('bar.dart', 'main() => "bar";')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp("Dependencies installed!\$"));

    dir(cachePath, [
      dir('git', [
        dir('cache', [
          gitPackageCacheDir('foo'),
          gitPackageCacheDir('bar')
        ]),
        gitPackageCacheDir('foo'),
        gitPackageCacheDir('bar')
      ])
    ]).scheduleValidate();

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ]),
      dir('bar', [
        file('bar.dart', 'main() => "bar";')
      ])
    ]).scheduleValidate();

    run();
  });

  test('checks out and updates a package from Git', () {
    ensureGit();

    git('foo.git', [
      file('foo.dart', 'main() => "foo";')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(cachePath, [
      dir('git', [
        dir('cache', [gitPackageCacheDir('foo')]),
        gitPackageCacheDir('foo')
      ])
    ]).scheduleValidate();

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    // TODO(nweiz): remove this once we support pub update
    dir(packagesPath).scheduleDelete();
    file('$appPath/pubspec.lock', '').scheduleDelete();

    git('foo.git', [
      file('foo.dart', 'main() => "foo 2";')
    ]).scheduleCommit();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    // When we download a new version of the git package, we should re-use the
    // git/cache directory but create a new git/ directory.
    dir(cachePath, [
      dir('git', [
        dir('cache', [gitPackageCacheDir('foo', 2)]),
        gitPackageCacheDir('foo'),
        gitPackageCacheDir('foo', 2)
      ])
    ]).scheduleValidate();

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo 2";')
      ])
    ]).scheduleValidate();

    run();
  });

  test('checks out a package from Git twice', () {
    ensureGit();

    git('foo.git', [
      file('foo.dart', 'main() => "foo";')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(cachePath, [
      dir('git', [
        dir('cache', [gitPackageCacheDir('foo')]),
        gitPackageCacheDir('foo')
      ])
    ]).scheduleValidate();

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    // TODO(nweiz): remove this once we support pub update
    dir(packagesPath).scheduleDelete();

    // Verify that nothing breaks if we install a Git revision that's already
    // in the cache.
    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    run();
  });

  test('checks out a package at a specific revision from Git', () {
    ensureGit();

    var repo = git('foo.git', [
      file('foo.dart', 'main() => "foo 1";')
    ]);
    repo.scheduleCreate();
    var commit = repo.revParse('HEAD');

    git('foo.git', [
      file('foo.dart', 'main() => "foo 2";')
    ]).scheduleCommit();

    appDir([{"git": {"url": "../foo.git", "ref": commit}}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo 1";')
      ])
    ]).scheduleValidate();

    run();
  });

  test('keeps a Git package locked to the version in the lockfile', () {
    ensureGit();

    git('foo.git', [
      file('foo.dart', 'main() => "foo";')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    // This install should lock the foo.git dependency to the current revision.
    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    // Delete the packages path to simulate a new checkout of the application.
    dir(packagesPath).scheduleDelete();

    git('foo.git', [
      file('foo.dart', 'main() => "foo 2";')
    ]).scheduleCommit();

    // This install shouldn't update the foo.git dependency due to the lockfile.
    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    run();
  });

  test('updates a locked Git package with a new incompatible constraint', () {
    ensureGit();

    git('foo.git', [
      file('foo.dart', 'main() => "foo";')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    git('foo.git', [
      file('foo.dart', 'main() => "foo 1.0.0";'),
      libPubspec("foo", "1.0.0")
    ]).scheduleCommit();

    appDir([{"git": "../foo.git", "version": ">=1.0.0"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo 1.0.0";')
      ])
    ]).scheduleValidate();

    run();
  });

  test("doesn't update a locked Git package with a new compatible "
      "constraint", () {
    ensureGit();

    git('foo.git', [
      file('foo.dart', 'main() => "foo 1.0.0";'),
      libPubspec("foo", "1.0.0")
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo 1.0.0";')
      ])
    ]).scheduleValidate();

    git('foo.git', [
      file('foo.dart', 'main() => "foo 1.0.1";'),
      libPubspec("foo", "1.0.1")
    ]).scheduleCommit();

    appDir([{"git": "../foo.git", "version": ">=1.0.0"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo 1.0.0";')
      ])
    ]).scheduleValidate();

    run();
  });
}
