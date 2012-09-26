// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('pub_tests');

#import('dart:io');

#import('test_pub.dart');
#import('../../../pkg/unittest/unittest.dart');

main() {
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

    schedulePub(args: ['update'],
        error: const RegExp('Could not resolve URL "http://pub.invalid".'),
        exitCode: 1);

    run();
  });

  test('fails gracefully if the package does not exist', () {
    servePackages([]);

    appDir([dependency("foo", "1.2.3")]).scheduleCreate();

    schedulePub(args: ['update'],
        error: const RegExp('Could not find package "foo" on '
                            'http://localhost:'),
        exitCode: 1);

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
        output: const RegExp(r"Dependencies installed!$"));

    packagesDir({
      "foo": "1.0.0",
      "foo-dep": "1.0.0"
    }).scheduleValidate();

    servePackages([
      package("foo", "2.0.0", [dependency("foo-dep", ">1.0.0")]),
      package("foo-dep", "2.0.0")
    ]);

    schedulePub(args: ['update', 'foo'],
        output: const RegExp(r"Dependencies updated!$"));

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
        output: const RegExp(r"Dependencies installed!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0"
    }).scheduleValidate();

    servePackages([
      package("foo", "2.0.0", [dependency("bar", "<3.0.0")]),
      package("bar", "2.0.0")
    ]);

    schedulePub(args: ['update', 'bar'],
        output: const RegExp(r"Dependencies updated!$"));

    packagesDir({
      "foo": "2.0.0",
      "bar": "2.0.0"
    }).scheduleValidate();

    run();
  });

  test("removes a dependency that's been removed from the pubspec", () {
    servePackages([
      package("foo", "1.0.0"),
      package("bar", "1.0.0")
    ]);

    appDir([dependency("foo"), dependency("bar")]).scheduleCreate();

    schedulePub(args: ['update'],
        output: const RegExp(r"Dependencies updated!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0"
    }).scheduleValidate();

    appDir([dependency("foo")]).scheduleCreate();

    schedulePub(args: ['update'],
        output: const RegExp(r"Dependencies updated!$"));

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

    schedulePub(args: ['update'],
        output: const RegExp(r"Dependencies updated!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0",
      "shared-dep": "1.0.0",
      "bar-dep": "1.0.0",
    }).scheduleValidate();

    appDir([dependency("foo")]).scheduleCreate();

    schedulePub(args: ['update'],
        output: const RegExp(r"Dependencies updated!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": null,
      "shared-dep": "1.0.0",
      "bar-dep": null,
    }).scheduleValidate();

    run();
  });

  test("updates dependencies whose constraints have been removed", () {
    servePackages([
      package("foo", "1.0.0", [dependency("shared-dep")]),
      package("bar", "1.0.0", [dependency("shared-dep", "<2.0.0")]),
      package("shared-dep", "1.0.0"),
      package("shared-dep", "2.0.0")
    ]);

    appDir([dependency("foo"), dependency("bar")]).scheduleCreate();

    schedulePub(args: ['update'],
        output: const RegExp(r"Dependencies updated!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0",
      "shared-dep": "1.0.0"
    }).scheduleValidate();

    appDir([dependency("foo")]).scheduleCreate();

    schedulePub(args: ['update'],
        output: const RegExp(r"Dependencies updated!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": null,
      "shared-dep": "2.0.0"
    }).scheduleValidate();

    run();
  });
}
