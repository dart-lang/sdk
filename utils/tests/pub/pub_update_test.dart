// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('pub_tests');

#import('dart:io');

#import('test_pub.dart');
#import('../../../pkg/unittest/unittest.dart');

main() {
  group('requires', () {
    test('a pubspec', () {
      dir(appPath, []).scheduleCreate();

      schedulePub(args: ['update'],
          error: const RegExp(@'^Could not find a file named "pubspec.yaml"'));

      run();
    });

    test('a pubspec with a "name" key', () {
      dir(appPath, [
        pubspec({"dependencies": {"foo": null}})
      ]).scheduleCreate();

      schedulePub(args: ['update'],
          error: const RegExp(@'^"pubspec.yaml" must contain a "name" key\.'));

      run();
    });
  });

  test('creates a self-referential symlink', () {
    // The symlink should use the name in the pubspec, not the name of the
    // directory.
    dir(appPath, [
      pubspec({"name": "myapp_name"})
    ]).scheduleCreate();

    schedulePub(args: ['update'],
        output: const RegExp(@"Dependencies updated!$"));

    dir(packagesPath, [
      dir("myapp_name", [pubspec({"name": "myapp_name"})])
    ]).scheduleValidate();

    run();
  });
}
