// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('pub_tests');

#import('dart:io');

#import('test_pub.dart');
#import('../../../pkg/unittest/lib/unittest.dart');

main() {
  group('requires', () {
    test('a pubspec', () {
      dir(appPath, []).scheduleCreate();

      schedulePub(args: ['install'],
          error: const RegExp(@'^Could not find a file named "pubspec.yaml"'),
          exitCode: 1);

      run();
    });

    test('a pubspec with a "name" key', () {
      dir(appPath, [
        pubspec({"dependencies": {"foo": null}})
      ]).scheduleCreate();

      schedulePub(args: ['install'],
          error: const RegExp(@'^"pubspec.yaml" is missing the required "name" '
              @'field \(e\.g\. "name: myapp"\)\.'),
          exitCode: 1);

      run();
    });
  });

  test('adds itself to the packages', () {
    // The symlink should use the name in the pubspec, not the name of the
    // directory.
    dir(appPath, [
      pubspec({"name": "myapp_name"}),
      libDir('foo'),
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(packagesPath, [
      dir("myapp_name", [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    run();
  });

  test('does not adds itself to the packages if it has no "lib" directory', () {
    // The symlink should use the name in the pubspec, not the name of the
    // directory.
    dir(appPath, [
      pubspec({"name": "myapp_name"}),
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(@"Dependencies installed!$"));

    dir(packagesPath, [
      nothing("myapp_name")
    ]).scheduleValidate();

    run();
  });

  test('does not add a package if it does not have a "lib" directory', () {
    // Using an SDK source, but this should be true of all sources.
    dir(sdkPath, [
      file('revision', '1234'),
      dir('pkg', [
        dir('foo', [])
      ])
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({"name": "myapp", "dependencies": {"foo": {"sdk": "foo"}}})
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        error: const RegExp(@'Warning: Package "foo" does not have a "lib" '
            'directory.'),
        output: const RegExp(@"Dependencies installed!$"));

    run();
  });

  group('creates a packages directory in', () {
    test('"test/" and its subdirectories', () {
      dir(appPath, [
        appPubspec([]),
        libDir('foo'),
        dir("test", [dir("subtest")])
      ]).scheduleCreate();

      schedulePub(args: ['install'],
          output: const RegExp(@"Dependencies installed!$"));

      dir(appPath, [
        dir("test", [
          dir("packages", [
            dir("myapp", [
              file('foo.dart', 'main() => "foo";')
            ])
          ]),
          dir("subtest", [
            dir("packages", [
              dir("myapp", [
                file('foo.dart', 'main() => "foo";')
              ])
            ])
          ])
        ])
      ]).scheduleValidate();

      run();
    });

    test('"example/" and its subdirectories', () {
      dir(appPath, [
        appPubspec([]),
        libDir('foo'),
        dir("example", [dir("subexample")])
      ]).scheduleCreate();

      schedulePub(args: ['install'],
          output: const RegExp(@"Dependencies installed!$"));

      dir(appPath, [
        dir("example", [
          dir("packages", [
            dir("myapp", [
              file('foo.dart', 'main() => "foo";')
            ])
          ]),
          dir("subexample", [
            dir("packages", [
              dir("myapp", [
                file('foo.dart', 'main() => "foo";')
              ])
            ])
          ])
        ])
      ]).scheduleValidate();

      run();
    });

    test('"bin/"', () {
      dir(appPath, [
        appPubspec([]),
        libDir('foo'),
        dir("bin")
      ]).scheduleCreate();

      schedulePub(args: ['install'],
          output: const RegExp(@"Dependencies installed!$"));

      dir(appPath, [
        dir("bin", [
          dir("packages", [
            dir("myapp", [
              file('foo.dart', 'main() => "foo";')
            ])
          ])
        ])
      ]).scheduleValidate();

      run();
    });
  });

  // TODO(rnystrom): Remove this when old layout support is removed. (#4964)
  test('shows a warning if the entrypoint uses the old layout', () {
    // The symlink should use the name in the pubspec, not the name of the
    // directory.
    dir(appPath, [
      pubspec({"name": "myapp_name"}),
      file("foo.dart", 'main() => "foo";'),
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        error: '''
        Warning: Package "myapp_name" is using a deprecated layout.
        See http://www.dartlang.org/docs/pub-package-manager/package-layout.html for details.
        ''',
        output: const RegExp(@"Dependencies installed!$"));

    run();
  });
}
