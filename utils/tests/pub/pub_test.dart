// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('pub_tests');

#import('dart:io');

#import('test_pub.dart');
#import('../../../pkg/unittest/unittest.dart');

final USAGE_STRING = """
    Pub is a package manager for Dart.

    Usage: pub command [arguments]

    Global options:
    -h, --help          Prints this usage information
        --version       Prints the version of Pub
        --[no-]trace    Prints a stack trace when an error occurs

    The commands are:
      help      display help information for Pub
      install   install the current package's dependencies
      list      print the contents of repositories
      update    update the current package's dependencies to the latest versions
      version   print Pub version

    Use "pub help [command]" for more information about a command.
    """;

final VERSION_STRING = '''
    Pub 0.0.0
    ''';

main() {
  test('running pub with no command displays usage', () =>
      runPub(args: [], output: USAGE_STRING));

  test('running pub with just --help displays usage', () =>
      runPub(args: ['--help'], output: USAGE_STRING));

  test('running pub with just -h displays usage', () =>
      runPub(args: ['-h'], output: USAGE_STRING));

  test('running pub with just --version displays version', () =>
      runPub(args: ['--version'], output: VERSION_STRING));

  group('an unknown command', () {
    test('displays an error message', () {
      runPub(args: ['quylthulg'],
          error: '''
          Unknown command "quylthulg".
          Run "pub help" to see available commands.
          ''',
          exitCode: 64);
    });
  });

  group('pub list', listCommand);
  group('pub install', installCommand);
  group('pub update', updateCommand);
  group('pub version', versionCommand);
}

listCommand() {
  // TODO(rnystrom): We don't currently have any sources that are cached, so
  // we can't test this right now.
  /*
  group('cache', () {
    test('treats an empty directory as a package', () {
      dir(cachePath, [
        dir('sdk', [
          dir('apple'),
          dir('banana'),
          dir('cherry')
        ])
      ]).scheduleCreate();

      runPub(args: ['list', 'cache'],
          output: '''
          From system cache:
            apple 0.0.0 (apple from sdk)
            banana 0.0.0 (banana from sdk)
            cherry 0.0.0 (cherry from sdk)
          ''');
    });
  });
  */
}

installCommand() {
  test('checks out a package from the SDK', () {
    dir(sdkPath, [
      file('revision', '1234'),
      dir('pkg', [packageDir("foo", "0.0.1234")])
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({"dependencies": {"foo": null}})
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: '''
        Dependencies installed!
        ''');

    packagesDir({"foo": "0.0.1234"}).scheduleValidate();

    run();
  });

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

  test('checks out a package from a pub server', () {
    servePackages([package("foo", "1.2.3")]);

    appDir([dependency("foo", "1.2.3")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp("Dependencies installed!\$"));

    cacheDir({"foo": "1.2.3"}).scheduleValidate();
    packagesDir({"foo": "1.2.3"}).scheduleValidate();

    run();
  });

  test('checks out packages transitively from a pub server', () {
    servePackages([
      package("foo", "1.2.3", [dependency("bar", "2.0.4")]),
      package("bar", "2.0.3"),
      package("bar", "2.0.4"),
      package("bar", "2.0.5")
    ]);

    appDir([dependency("foo", "1.2.3")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp("Dependencies installed!\$"));

    cacheDir({"foo": "1.2.3", "bar": "2.0.4"}).scheduleValidate();
    packagesDir({"foo": "1.2.3", "bar": "2.0.4"}).scheduleValidate();

    run();
  });

  test('resolves version constraints from a pub server', () {
    servePackages([
      package("foo", "1.2.3", [dependency("baz", ">=2.0.0")]),
      package("bar", "2.3.4", [dependency("baz", "<3.0.0")]),
      package("baz", "2.0.3"),
      package("baz", "2.0.4"),
      package("baz", "3.0.1")
    ]);

    appDir([dependency("foo"), dependency("bar")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp("Dependencies installed!\$"));

    cacheDir({
      "foo": "1.2.3",
      "bar": "2.3.4",
      "baz": "2.0.4"
    }).scheduleValidate();

    packagesDir({
      "foo": "1.2.3",
      "bar": "2.3.4",
      "baz": "2.0.4"
    }).scheduleValidate();

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

  test('keeps a pub server package locked to the version in the lockfile', () {
    servePackages([package("foo", "1.0.0")]);

    appDir([dependency("foo")]).scheduleCreate();

    // This install should lock the foo dependency to version 1.0.0.
    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({"foo": "1.0.0"}).scheduleValidate();

    // Delete the packages path to simulate a new checkout of the application.
    dir(packagesPath).scheduleDelete();

    // Start serving a newer package as well.
    servePackages([package("foo", "1.0.1")]);

    // This install shouldn't update the foo dependency due to the lockfile.
    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({"foo": "1.0.0"}).scheduleValidate();

    run();
  });

  test('updates a locked pub server package with a new incompatible '
      'constraint', () {
    servePackages([package("foo", "1.0.0")]);

    appDir([dependency("foo")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({"foo": "1.0.0"}).scheduleValidate();

    servePackages([package("foo", "1.0.1")]);

    appDir([dependency("foo", ">1.0.0")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({"foo": "1.0.1"}).scheduleValidate();

    run();
  });

  test("doesn't update a locked pub server package with a new compatible "
      "constraint", () {
    servePackages([package("foo", "1.0.0")]);

    appDir([dependency("foo")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({"foo": "1.0.0"}).scheduleValidate();

    servePackages([package("foo", "1.0.1")]);

    appDir([dependency("foo", ">=1.0.0")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({"foo": "1.0.0"}).scheduleValidate();

    run();
  });

  test("unlocks dependencies if necessary to ensure that a new dependency "
      "is satisfied", () {
    servePackages([
      package("foo", "1.0.0", [dependency("bar", "<2.0.0")]),
      package("bar", "1.0.0", [dependency("baz", "<2.0.0")]),
      package("baz", "1.0.0", [dependency("qux", "<2.0.0")]),
      package("qux", "1.0.0")
    ]);

    appDir([dependency("foo")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0",
      "baz": "1.0.0",
      "qux": "1.0.0"
    }).scheduleValidate();

    servePackages([
      package("foo", "2.0.0", [dependency("bar", "<3.0.0")]),
      package("bar", "2.0.0", [dependency("baz", "<3.0.0")]),
      package("baz", "2.0.0", [dependency("qux", "<3.0.0")]),
      package("qux", "2.0.0"),
      package("newdep", "2.0.0", [dependency("baz", ">=1.5.0")])
    ]);

    appDir([dependency("foo"), dependency("newdep")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({
      "foo": "2.0.0",
      "bar": "2.0.0",
      "baz": "2.0.0",
      "qux": "1.0.0",
      "newdep": "2.0.0"
    }).scheduleValidate();

    run();
  });

  test("doesn't unlock dependencies if a new dependency is already "
      "satisfied", () {
    servePackages([
      package("foo", "1.0.0", [dependency("bar", "<2.0.0")]),
      package("bar", "1.0.0", [dependency("baz", "<2.0.0")]),
      package("baz", "1.0.0")
    ]);

    appDir([dependency("foo")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0",
      "baz": "1.0.0"
    }).scheduleValidate();

    servePackages([
      package("foo", "2.0.0", [dependency("bar", "<3.0.0")]),
      package("bar", "2.0.0", [dependency("baz", "<3.0.0")]),
      package("baz", "2.0.0"),
      package("newdep", "2.0.0", [dependency("baz", ">=1.0.0")])
    ]);

    appDir([dependency("foo"), dependency("newdep")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0",
      "baz": "1.0.0",
      "newdep": "2.0.0"
    }).scheduleValidate();

    run();
  });
}

updateCommand() {
  test("updates locked Git packages", () {
    ensureGit();

    git('foo.git', [
      file('foo.dart', 'main() => "foo";')
    ]).scheduleCreate();

    git('bar.git', [
      file('bar.dart', 'main() => "bar";')
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
      file('foo.dart', 'main() => "foo 2";')
    ]).scheduleCommit();

    git('bar.git', [
      file('bar.dart', 'main() => "bar 2";')
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
        file('foo.dart', 'main() => "foo";')
      ]).scheduleCreate();

      git('bar.git', [
        file('bar.dart', 'main() => "bar";')
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
        file('foo.dart', 'main() => "foo 2";')
      ]).scheduleCommit();

      git('bar.git', [
        file('bar.dart', 'main() => "bar 2";')
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
        file('foo.dart', 'main() => "foo";'),
        libPubspec("foo", "1.0.0", [{"git": "../foo-dep.git"}])
      ]).scheduleCreate();

      git('foo-dep.git', [
        file('foo-dep.dart', 'main() => "foo-dep";'),
      ]).scheduleCreate();

      appDir([{"git": "../foo.git"}]).scheduleCreate();

      schedulePub(args: ['install'],
          output: const RegExp(@"Dependencies installed!$"));

      dir(packagesPath, [
        dir('foo', [
          file('foo.dart', 'main() => "foo";'),
          libPubspec("foo", "1.0.0", [{"git": "../foo-dep.git"}])
        ]),
        dir('foo-dep', [
          file('foo-dep.dart', 'main() => "foo-dep";')
        ])
      ]).scheduleValidate();

      git('foo.git', [
        file('foo.dart', 'main() => "foo 2";'),
        libPubspec("foo", "1.0.0", [{"git": "../foo-dep.git"}])
      ]).scheduleCreate();

      git('foo-dep.git', [
        file('foo-dep.dart', 'main() => "foo-dep 2";')
      ]).scheduleCommit();

      schedulePub(args: ['update', 'foo'],
          output: const RegExp(@"Dependencies updated!$"));

      dir(packagesPath, [
        dir('foo', [
          file('foo.dart', 'main() => "foo 2";'),
          libPubspec("foo", "1.0.0", [{"git": "../foo-dep.git"}])
        ]),
        dir('foo-dep', [
          file('foo-dep.dart', 'main() => "foo-dep";')
        ]),
      ]).scheduleValidate();

      run();
    });

    test("updates one locked pub server package's dependencies if it's "
        "necessary", () {
      servePackages([
        package("foo", "1.0.0", [dependency("foo-dep")]),
        package("foo-dep", "1.0.0")
      ]);

      appDir([dependency("foo")]).scheduleCreate();

      schedulePub(args: ['install'],
          output: const RegExp(@"Dependencies installed!$"));

      packagesDir({
        "foo": "1.0.0",
        "foo-dep": "1.0.0"
      }).scheduleValidate();

      servePackages([
        package("foo", "2.0.0", [dependency("foo-dep", ">1.0.0")]),
        package("foo-dep", "2.0.0")
      ]);

      schedulePub(args: ['update', 'foo'],
          output: const RegExp(@"Dependencies updated!$"));

      packagesDir({
        "foo": "2.0.0",
        "foo-dep": "2.0.0"
      }).scheduleValidate();

      run();
    });

    test("updates a locked package's dependers in order to get it to max "
        "version", () {
      servePackages([
        package("foo", "1.0.0", [dependency("bar", "<2.0.0")]),
        package("bar", "1.0.0")
      ]);

      appDir([dependency("foo"), dependency("bar")]).scheduleCreate();

      schedulePub(args: ['install'],
          output: const RegExp(@"Dependencies installed!$"));

      packagesDir({
        "foo": "1.0.0",
        "bar": "1.0.0"
      }).scheduleValidate();

      servePackages([
        package("foo", "2.0.0", [dependency("bar", "<3.0.0")]),
        package("bar", "2.0.0")
      ]);

      schedulePub(args: ['update', 'bar'],
          output: const RegExp(@"Dependencies updated!$"));

      packagesDir({
        "foo": "2.0.0",
        "bar": "2.0.0"
      }).scheduleValidate();

      run();
    });
  });
}

versionCommand() {
  test('displays the current version', () =>
    runPub(args: ['version'], output: VERSION_STRING));
}
