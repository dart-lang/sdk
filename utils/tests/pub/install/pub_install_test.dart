// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE d.file.

library pub_tests;

import 'dart:io';

import 'package:pathos/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../../pub/io.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  group('requires', () {
    integration('a pubspec', () {
      d.dir(appPath, []).create();

      schedulePub(args: ['install'],
          error: new RegExp(r'^Could not find a file named "pubspec\.yaml"'),
          exitCode: 1);
    });

    integration('a pubspec with a "name" key', () {
      d.dir(appPath, [
        d.pubspec({"dependencies": {"foo": null}})
      ]).create();

      schedulePub(args: ['install'],
          error: new RegExp(r'^pubspec.yaml is missing the required "name" '
              r'field \(e\.g\. "name: myapp"\)\.'),
          exitCode: 1);
    });
  });

  integration('adds itself to the packages', () {
    // The symlink should use the name in the pubspec, not the name of the
    // directory.
    d.dir(appPath, [
      d.pubspec({"name": "myapp_name"}),
      d.libDir('foo'),
    ]).create();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    d.dir(packagesPath, [
      d.dir("myapp_name", [
        d.file('foo.dart', 'main() => "foo";')
      ])
    ]).validate();
  });

  integration('does not add itself to the packages if it has no "lib" directory', () {
    // The symlink should use the name in the pubspec, not the name of the
    // directory.
    d.dir(appPath, [
      d.pubspec({"name": "myapp_name"}),
    ]).create();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    d.dir(packagesPath, [
      d.nothing("myapp_name")
    ]).validate();
  });

  integration('does not add a package if it does not have a "lib" directory', () {
    // Using a path source, but this should be true of all sources.
    d.dir('foo', [
      d.libPubspec('foo', '0.0.0-not.used')
    ]).create();

    d.dir(appPath, [
      d.pubspec({"name": "myapp", "dependencies": {"foo": {"path": "../foo"}}})
    ]).create();

    schedulePub(args: ['install'],
        error: new RegExp(r'Warning: Package "foo" does not have a "lib" '
            'directory so you will not be able to import any libraries from '
            'it.'),
        output: new RegExp(r"Dependencies installed!$"));
  });

  integration('reports a solver failure', () {
    // myapp depends on foo and bar which both depend on baz with mismatched
    // descriptions.
    d.dir('deps', [
      d.dir('foo', [
        d.pubspec({"name": "foo", "dependencies": {
          "baz": {"path": "../baz1"}
        }})
      ]),
      d.dir('bar', [
        d.pubspec({"name": "bar", "dependencies": {
          "baz": {"path": "../baz2"}
        }})
      ]),
      d.dir('baz1', [
        d.libPubspec('baz', '0.0.0')
      ]),
      d.dir('baz2', [
        d.libPubspec('baz', '0.0.0')
      ])
    ]).create();

    d.dir(appPath, [
      d.pubspec({"name": "myapp", "dependencies": {
        "foo": {"path": "../deps/foo"},
        "bar": {"path": "../deps/bar"}
      }})
    ]).create();

    schedulePub(args: ['install'],
        error: new RegExp(r"^Incompatible dependencies on 'baz':"),
        exitCode: 1);
  });

  integration('does not warn if the root package lacks a "lib" directory', () {
    d.dir(appPath, [
      d.appPubspec([])
    ]).create();

    schedulePub(args: ['install'],
        error: new RegExp(r'^\s*$'),
        output: new RegExp(r"Dependencies installed!$"));
  });

  integration('overwrites the existing packages directory', () {
    d.dir(appPath, [
      d.appPubspec([]),
      d.dir('packages', [
        d.dir('foo'),
        d.dir('myapp'),
      ]),
      d.libDir('myapp')
    ]).create();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    d.dir(packagesPath, [
      d.nothing('foo'),
      d.dir('myapp', [d.file('myapp.dart', 'main() => "myapp";')])
    ]).validate();
  });

  integration('overwrites a broken packages directory symlink', () {
    d.dir(appPath, [
      d.appPubspec([]),
      d.dir('packages'),
      d.libDir('myapp'),
      d.dir('bin')
    ]).create();

    scheduleSymlink(
        path.join(appPath, 'packages'),
        path.join(appPath, 'bin', 'packages'));

    schedule(() => deleteEntry(path.join(sandboxDir, appPath, 'packages')));

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    d.dir(packagesPath, [
      d.nothing('foo'),
      d.dir('myapp', [d.file('myapp.dart', 'main() => "myapp";')])
    ]).validate();
  });

  group('creates a packages directory in', () {
    integration('"test/" and its subdirectories', () {
      d.dir(appPath, [
        d.appPubspec([]),
        d.libDir('foo'),
        d.dir("test", [d.dir("subtest")])
      ]).create();

      schedulePub(args: ['install'],
          output: new RegExp(r"Dependencies installed!$"));

      d.dir(appPath, [
        d.dir("test", [
          d.dir("packages", [
            d.dir("myapp", [
              d.file('foo.dart', 'main() => "foo";')
            ])
          ]),
          d.dir("subtest", [
            d.dir("packages", [
              d.dir("myapp", [
                d.file('foo.dart', 'main() => "foo";')
              ])
            ])
          ])
        ])
      ]).validate();
    });

    integration('"example/" and its subdirectories', () {
      d.dir(appPath, [
        d.appPubspec([]),
        d.libDir('foo'),
        d.dir("example", [d.dir("subexample")])
      ]).create();

      schedulePub(args: ['install'],
          output: new RegExp(r"Dependencies installed!$"));

      d.dir(appPath, [
        d.dir("example", [
          d.dir("packages", [
            d.dir("myapp", [
              d.file('foo.dart', 'main() => "foo";')
            ])
          ]),
          d.dir("subexample", [
            d.dir("packages", [
              d.dir("myapp", [
                d.file('foo.dart', 'main() => "foo";')
              ])
            ])
          ])
        ])
      ]).validate();
    });

    integration('"tool/" and its subdirectories', () {
      d.dir(appPath, [
        d.appPubspec([]),
        d.libDir('foo'),
        d.dir("tool", [d.dir("subtool")])
      ]).create();

      schedulePub(args: ['install'],
          output: new RegExp(r"Dependencies installed!$"));

      d.dir(appPath, [
        d.dir("tool", [
          d.dir("packages", [
            d.dir("myapp", [
              d.file('foo.dart', 'main() => "foo";')
            ])
          ]),
          d.dir("subtool", [
            d.dir("packages", [
              d.dir("myapp", [
                d.file('foo.dart', 'main() => "foo";')
              ])
            ])
          ])
        ])
      ]).validate();
    });

    integration('"web/" and its subdirectories', () {
      d.dir(appPath, [
        d.appPubspec([]),
        d.libDir('foo'),
        d.dir("web", [d.dir("subweb")])
      ]).create();

      schedulePub(args: ['install'],
          output: new RegExp(r"Dependencies installed!$"));

      d.dir(appPath, [
        d.dir("web", [
          d.dir("packages", [
            d.dir("myapp", [
              d.file('foo.dart', 'main() => "foo";')
            ])
          ]),
          d.dir("subweb", [
            d.dir("packages", [
              d.dir("myapp", [
                d.file('foo.dart', 'main() => "foo";')
              ])
            ])
          ])
        ])
      ]).validate();
    });

    integration('"bin/"', () {
      d.dir(appPath, [
        d.appPubspec([]),
        d.libDir('foo'),
        d.dir("bin")
      ]).create();

      schedulePub(args: ['install'],
          output: new RegExp(r"Dependencies installed!$"));

      d.dir(appPath, [
        d.dir("bin", [
          d.dir("packages", [
            d.dir("myapp", [
              d.file('foo.dart', 'main() => "foo";')
            ])
          ])
        ])
      ]).validate();
    });
  });
}
