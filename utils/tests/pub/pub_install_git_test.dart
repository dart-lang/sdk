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
      libDir('foo'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(cachePath, [
      dir('git', [
        dir('cache', [gitPackageRepoCacheDir('foo')]),
        gitPackageRevisionCacheDir('foo')
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
      libDir('foo'),
      libPubspec('foo', '1.0.0', [{"git": "../bar.git"}])
    ]).scheduleCreate();

    git('bar.git', [
      libDir('bar'),
      libPubspec('bar', '1.0.0')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp("Dependencies installed!\$"));

    dir(cachePath, [
      dir('git', [
        dir('cache', [
          gitPackageRepoCacheDir('foo'),
          gitPackageRepoCacheDir('bar')
        ]),
        gitPackageRevisionCacheDir('foo'),
        gitPackageRevisionCacheDir('bar')
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

  test('doesn\'t require the repository name to match the name in the '
      'pubspec', () {
    ensureGit();

    git('foo.git', [
      libDir('weirdname'),
      libPubspec('weirdname', '1.0.0')
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "weirdname": {"git": "../foo.git"}
        }
      })
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir('weirdname', [
        file('weirdname.dart', 'main() => "weirdname";')
      ])
    ]).scheduleValidate();

    run();
  });

  test('requires the dependency to have a pubspec', () {
    ensureGit();

    git('foo.git', [
      libDir('foo')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    // TODO(nweiz): clean up this RegExp when either issue 4706 or 4707 is
    // fixed.
    schedulePub(args: ['install'],
        error: const RegExp('^Package "foo" doesn\'t have a '
            'pubspec.yaml file.'),
        exitCode: 1);

    run();
  });

  test('requires the dependency to have a pubspec with a name field', () {
    ensureGit();

    git('foo.git', [
      libDir('foo'),
      pubspec({})
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    // TODO(nweiz): clean up this RegExp when either issue 4706 or 4707 is
    // fixed.
    schedulePub(args: ['install'],
        error: const RegExp(r'^Package "foo"' "'" 's pubspec.yaml file is '
            r'missing the required "name" field \(e\.g\. "name: foo"\)\.'),
        exitCode: 1);

    run();
  });

  test('requires the dependency name to match the remote pubspec name', () {
    ensureGit();

    git('foo.git', [
      libDir('foo'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "weirdname": {"git": "../foo.git"}
        }
      })
    ]).scheduleCreate();

    // TODO(nweiz): clean up this RegExp when either issue 4706 or 4707 is
    // fixed.
    schedulePub(args: ['install'],
        error: const RegExp(r'^The name you specified for your dependency, '
            '"weirdname", doesn\'t match the name "foo" in its '
            r'pubspec\.'),
        exitCode: 1);

    run();
  });

  test('checks out and updates a package from Git', () {
    ensureGit();

    git('foo.git', [
      libDir('foo'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(cachePath, [
      dir('git', [
        dir('cache', [gitPackageRepoCacheDir('foo')]),
        gitPackageRevisionCacheDir('foo')
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
      libDir('foo', 'foo 2'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCommit();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    // When we download a new version of the git package, we should re-use the
    // git/cache directory but create a new git/ directory.
    dir(cachePath, [
      dir('git', [
        dir('cache', [gitPackageRepoCacheDir('foo')]),
        gitPackageRevisionCacheDir('foo'),
        gitPackageRevisionCacheDir('foo', 2)
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
      libDir('foo'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(cachePath, [
      dir('git', [
        dir('cache', [gitPackageRepoCacheDir('foo')]),
        gitPackageRevisionCacheDir('foo')
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
        output: const RegExp(r"Dependencies installed!$"));

    run();
  });

  test('checks out a package at a specific revision from Git', () {
    ensureGit();

    var repo = git('foo.git', [
      libDir('foo', 'foo 1'),
      libPubspec('foo', '1.0.0')
    ]);
    repo.scheduleCreate();
    var commit = repo.revParse('HEAD');

    git('foo.git', [
      libDir('foo', 'foo 2'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCommit();

    appDir([{"git": {"url": "../foo.git", "ref": commit}}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo 1";')
      ])
    ]).scheduleValidate();

    run();
  });

  test('checks out a package at a specific branch from Git', () {
    ensureGit();

    var repo = git('foo.git', [
      libDir('foo', 'foo 1'),
      libPubspec('foo', '1.0.0')
    ]);
    repo.scheduleCreate();
    repo.scheduleGit(["branch", "old"]);

    git('foo.git', [
      libDir('foo', 'foo 2'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCommit();

    appDir([{"git": {"url": "../foo.git", "ref": "old"}}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

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
      libDir('foo'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    // This install should lock the foo.git dependency to the current revision.
    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    // Delete the packages path to simulate a new checkout of the application.
    dir(packagesPath).scheduleDelete();

    git('foo.git', [
      libDir('foo', 'foo 2'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCommit();

    // This install shouldn't update the foo.git dependency due to the lockfile.
    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

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
      libDir('foo'),
      libPubspec('foo', '0.5.0')
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
      libDir('foo', 'foo 1.0.0'),
      libPubspec("foo", "1.0.0")
    ]).scheduleCommit();

    appDir([{"git": "../foo.git", "version": ">=1.0.0"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

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
      libDir('foo', 'foo 1.0.0'),
      libPubspec("foo", "1.0.0")
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo 1.0.0";')
      ])
    ]).scheduleValidate();

    git('foo.git', [
      libDir('foo', 'foo 1.0.1'),
      libPubspec("foo", "1.0.1")
    ]).scheduleCommit();

    appDir([{"git": "../foo.git", "version": ">=1.0.0"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo 1.0.0";')
      ])
    ]).scheduleValidate();

    run();
  });

  group("(regression)", () {
    test('checks out a package from Git with a trailing slash', () {
      ensureGit();

      git('foo.git', [
        libDir('foo'),
        libPubspec('foo', '1.0.0')
      ]).scheduleCreate();

      appDir([{"git": "../foo.git/"}]).scheduleCreate();

      schedulePub(args: ['install'],
          output: const RegExp(r"Dependencies installed!$"));

      dir(cachePath, [
        dir('git', [
          dir('cache', [gitPackageRepoCacheDir('foo')]),
          gitPackageRevisionCacheDir('foo')
        ])
      ]).scheduleValidate();

      dir(packagesPath, [
        dir('foo', [
          file('foo.dart', 'main() => "foo";')
        ])
      ]).scheduleValidate();

      run();
    });
  });
}
