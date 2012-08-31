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

      schedulePub(args: ['install'],
          error: const RegExp(@'^Could not find a file named "pubspec.yaml"'));

      run();
    });

    test('a pubspec with a "name" key', () {
      dir(appPath, [
        pubspec({"dependencies": {"foo": null}})
      ]).scheduleCreate();

      schedulePub(args: ['install'],
          error: const RegExp(@'^"pubspec.yaml" is missing the required "name" '
              @'field \(e\.g\. "name: myapp"\)\.'));

      run();
    });
  });

  // TODO(rnystrom): Re-enable this when #4820 is fixed.
  /*
  test('creates a self-referential symlink', () {
    // The symlink should use the name in the pubspec, not the name of the
    // directory.
    dir(appPath, [
      pubspec({"name": "myapp_name"})
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(packagesPath, [
      dir("myapp_name", [pubspec({"name": "myapp_name"})])
    ]).scheduleValidate();

    run();
  });
  */

  group('creates a packages directory in', () {
    test('"test/" and its subdirectories', () {
      dir(appPath, [
        appPubspec([]),
        dir("test", [dir("subtest")])
      ]).scheduleCreate();

      schedulePub(args: ['install'],
          output: const RegExp(@"Dependencies installed!$"));

      dir(appPath, [
        dir("test", [
          dir("packages", [
            // TODO(rnystrom): Re-enable this when #4820 is fixed.
            /*
            dir("myapp", [appPubspec([])])
            */
          ]),
          dir("subtest", [
            dir("packages", [
              // TODO(rnystrom): Re-enable this when #4820 is fixed.
              /*
              dir("myapp", [appPubspec([])])
              */
            ])
          ])
        ])
      ]).scheduleValidate();

      run();
    });

    test('"example/" and its subdirectories', () {
      dir(appPath, [
        appPubspec([]),
        dir("example", [dir("subexample")])
      ]).scheduleCreate();

      schedulePub(args: ['install'],
          output: const RegExp(@"Dependencies installed!$"));

      dir(appPath, [
        dir("example", [
          dir("packages", [
            // TODO(rnystrom): Re-enable this when #4820 is fixed.
            /*
            dir("myapp", [appPubspec([])])
            */
          ]),
          dir("subexample", [
            dir("packages", [
              // TODO(rnystrom): Re-enable this when #4820 is fixed.
              /*
              dir("myapp", [appPubspec([])])
              */
            ])
          ])
        ])
      ]).scheduleValidate();

      run();
    });

    test('"bin/"', () {
      dir(appPath, [
        appPubspec([]),
        dir("bin")
      ]).scheduleCreate();

      schedulePub(args: ['install'],
          output: const RegExp(@"Dependencies installed!$"));

      dir(appPath, [
        dir("bin", [
          dir("packages", [
            // TODO(rnystrom): Re-enable this when #4820 is fixed.
            /*
            dir("myapp", [appPubspec([])])
            */
          ])
        ])
      ]).scheduleValidate();

      run();
    });
  });
}
