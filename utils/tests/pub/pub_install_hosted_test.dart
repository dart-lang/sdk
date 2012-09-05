// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('pub_tests');

#import('dart:io');

#import('test_pub.dart');
#import('../../../pkg/unittest/unittest.dart');

main() {
  test('checks out a package from a pub server', () {
    servePackages([package("foo", "1.2.3")]);

    appDir([dependency("foo", "1.2.3")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp("Dependencies installed!\$"));

    cacheDir({"foo": "1.2.3"}).scheduleValidate();
    packagesDir({"foo": "1.2.3"}).scheduleValidate();

    run();
  });

  test('fails gracefully if the url does not resolve', () {
    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "hosted": {
              "name": "foo",
              "url": "http://pub.invalid"
            }
          }
         }
      })
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        error: const RegExp('Could not resolve URL "http://pub.invalid".'));

    run();
  });

  test('fails gracefully if the package does not exist', () {
    servePackages([]);

    appDir([dependency("foo", "1.2.3")]).scheduleCreate();

    schedulePub(args: ['install'],
        error: const RegExp('Could not find package "foo" on '
                            'http://localhost:'));

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

  test("removes a dependency that's been removed from the pubspec", () {
    servePackages([
      package("foo", "1.0.0"),
      package("bar", "1.0.0")
    ]);

    appDir([dependency("foo"), dependency("bar")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0"
    }).scheduleValidate();

    appDir([dependency("foo")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": null
    }).scheduleValidate();

    run();
  });

  test("removes a transitive dependency that's no longer depended on", () {
    servePackages([
      package("foo", "1.0.0", [dependency("shared-dep")]),
      package("bar", "1.0.0", [
        dependency("shared-dep"),
        dependency("bar-dep")
      ]),
      package("shared-dep", "1.0.0"),
      package("bar-dep", "1.0.0")
    ]);

    appDir([dependency("foo"), dependency("bar")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0",
      "shared-dep": "1.0.0",
      "bar-dep": "1.0.0",
    }).scheduleValidate();

    appDir([dependency("foo")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": null,
      "shared-dep": "1.0.0",
      "bar-dep": null,
    }).scheduleValidate();

    run();
  });

  test("doesn't update dependencies whose constraints have been removed", () {
    servePackages([
      package("foo", "1.0.0", [dependency("shared-dep")]),
      package("bar", "1.0.0", [dependency("shared-dep", "<2.0.0")]),
      package("shared-dep", "1.0.0"),
      package("shared-dep", "2.0.0")
    ]);

    appDir([dependency("foo"), dependency("bar")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0",
      "shared-dep": "1.0.0"
    }).scheduleValidate();

    appDir([dependency("foo")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": null,
      "shared-dep": "1.0.0"
    }).scheduleValidate();

    run();
  });
}
