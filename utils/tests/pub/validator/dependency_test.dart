// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:json' as json;

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pathos/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../../pub/entrypoint.dart';
import '../../../pub/validator.dart';
import '../../../pub/validator/dependency.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

Validator dependency(Entrypoint entrypoint) =>
  new DependencyValidator(entrypoint);

expectDependencyValidationError(String error) {
  expect(schedulePackageValidation(dependency),
      completion(pairOf(someElement(contains(error)), isEmpty)));
}

expectDependencyValidationWarning(String warning) {
  expect(schedulePackageValidation(dependency),
      completion(pairOf(isEmpty, someElement(contains(warning)))));
}

/// Sets up a test package with dependency [dep] and mocks a server with
/// [hostedVersions] of the package available.
setUpDependency(Map dep, {List<String> hostedVersions}) {
  useMockClient(new MockClient((request) {
    expect(request.method, equals("GET"));
    expect(request.url.path, equals("/packages/foo.json"));

    if (hostedVersions == null) {
      return new Future.value(new http.Response("not found", 404));
    } else {
      return new Future.value(new http.Response(json.stringify({
        "name": "foo",
        "uploaders": ["nweiz@google.com"],
        "versions": hostedVersions
      }), 200));
    }
  }));

  d.dir(appPath, [
    d.libPubspec("test_pkg", "1.0.0", deps: [dep])
  ]).create();
}

main() {
  initConfig();

  integration('should consider a package valid if it looks normal', () {
    d.validPackage.create();
    expectNoValidationError(dependency);
  });

  group('should consider a package invalid if it', () {
    setUp(d.validPackage.create);

    group('has a git dependency', () {
      group('where a hosted version exists', () {
        integration("and should suggest the hosted primary version", () {
          setUpDependency({'git': 'git://github.com/dart-lang/foo'},
              hostedVersions: ["3.0.0-pre", "2.0.0", "1.0.0"]);
          expectDependencyValidationWarning('  foo: ">=2.0.0 <3.0.0"');
        });

        integration("and should suggest the hosted prerelease version if "
                    "it's the only version available", () {
          setUpDependency({'git': 'git://github.com/dart-lang/foo'},
              hostedVersions: ["3.0.0-pre", "2.0.0-pre"]);
          expectDependencyValidationWarning('  foo: ">=3.0.0-pre <4.0.0"');
        });

        integration("and should suggest a tighter constraint if primary is "
                    "pre-1.0.0", () {
          setUpDependency({'git': 'git://github.com/dart-lang/foo'},
              hostedVersions: ["0.0.1", "0.0.2"]);
          expectDependencyValidationWarning('  foo: ">=0.0.2 <0.0.3"');
        });
      });

      group('where no hosted version exists', () {
        integration("and should use the other source's version", () {
          setUpDependency({
            'git': 'git://github.com/dart-lang/foo',
            'version': '>=1.0.0 <2.0.0'
          });
          expectDependencyValidationWarning('  foo: ">=1.0.0 <2.0.0"');
        });

        integration("and should use the other source's unquoted version if "
                    "concrete", () {
          setUpDependency({
            'git': 'git://github.com/dart-lang/foo',
            'version': '0.2.3'
          });
          expectDependencyValidationWarning('  foo: 0.2.3');
        });
      });
    });

    group('has a path dependency', () {
      group('where a hosted version exists', () {
        integration("and should suggest the hosted primary version", () {
          setUpDependency({'path': path.join(sandboxDir, 'foo')},
              hostedVersions: ["3.0.0-pre", "2.0.0", "1.0.0"]);
          expectDependencyValidationError('  foo: ">=2.0.0 <3.0.0"');
        });

        integration("and should suggest the hosted prerelease version if "
                    "it's the only version available", () {
          setUpDependency({'path': path.join(sandboxDir, 'foo')},
              hostedVersions: ["3.0.0-pre", "2.0.0-pre"]);
          expectDependencyValidationError('  foo: ">=3.0.0-pre <4.0.0"');
        });

        integration("and should suggest a tighter constraint if primary is "
                    "pre-1.0.0", () {
          setUpDependency({'path': path.join(sandboxDir, 'foo')},
              hostedVersions: ["0.0.1", "0.0.2"]);
          expectDependencyValidationError('  foo: ">=0.0.2 <0.0.3"');
        });
      });

      group('where no hosted version exists', () {
        integration("and should use the other source's version", () {
          setUpDependency({
            'path': path.join(sandboxDir, 'foo'),
            'version': '>=1.0.0 <2.0.0'
          });
          expectDependencyValidationError('  foo: ">=1.0.0 <2.0.0"');
        });

        integration("and should use the other source's unquoted version if "
                    "concrete", () {
          setUpDependency({
            'path': path.join(sandboxDir, 'foo'),
            'version': '0.2.3'
          });
          expectDependencyValidationError('  foo: 0.2.3');
        });
      });
    });

    group('has an unconstrained dependency', () {
      group('and it should not suggest a version', () {
        integration("if there's no lockfile", () {
          d.dir(appPath, [
            d.libPubspec("test_pkg", "1.0.0", deps: [
              {'hosted': 'foo'}
            ])
          ]).create();

          expect(schedulePackageValidation(dependency), completion(
              pairOf(isEmpty, everyElement(isNot(contains("\n  foo:"))))));
        });

        integration("if the lockfile doesn't have an entry for the "
            "dependency", () {
          d.dir(appPath, [
            d.libPubspec("test_pkg", "1.0.0", deps: [
              {'hosted': 'foo'}
            ]),
            d.file("pubspec.lock", json.stringify({
              'packages': {
                'bar': {
                  'version': '1.2.3',
                  'source': 'hosted',
                  'description': {
                    'name': 'bar',
                    'url': 'http://pub.dartlang.org'
                  }
                }
              }
            }))
          ]).create();

          expect(schedulePackageValidation(dependency), completion(
              pairOf(isEmpty, everyElement(isNot(contains("\n  foo:"))))));
        });
      });

      group('with a lockfile', () {
        integration('and it should suggest a constraint based on the locked '
            'version', () {
          d.dir(appPath, [
            d.libPubspec("test_pkg", "1.0.0", deps: [
              {'hosted': 'foo'}
            ]),
            d.file("pubspec.lock", json.stringify({
              'packages': {
                'foo': {
                  'version': '1.2.3',
                  'source': 'hosted',
                  'description': {
                    'name': 'foo',
                    'url': 'http://pub.dartlang.org'
                  }
                }
              }
            }))
          ]).create();

          expectDependencyValidationWarning('  foo: ">=1.2.3 <2.0.0"');
        });

        integration('and it should suggest a concrete constraint if the locked '
            'version is pre-1.0.0', () {
          d.dir(appPath, [
            d.libPubspec("test_pkg", "1.0.0", deps: [
              {'hosted': 'foo'}
            ]),
            d.file("pubspec.lock", json.stringify({
              'packages': {
                'foo': {
                  'version': '0.1.2',
                  'source': 'hosted',
                  'description': {
                    'name': 'foo',
                    'url': 'http://pub.dartlang.org'
                  }
                }
              }
            }))
          ]).create();

          expectDependencyValidationWarning('  foo: ">=0.1.2 <0.1.3"');
        });
      });
    });

    integration('has a hosted dependency on itself', () {
      d.dir(appPath, [
        d.libPubspec("test_pkg", "1.0.0", deps: [
          {'hosted': {'name': 'test_pkg', 'version': '>=1.0.0'}}
        ])
      ]).create();

      expectValidationWarning(dependency);
    });
  });
}
