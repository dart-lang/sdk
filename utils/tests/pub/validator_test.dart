// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library validator_test;

import 'dart:async';
import 'dart:io';
import 'dart:json' as json;
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pathos/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../pub/entrypoint.dart';
import '../../pub/io.dart';
import '../../pub/validator.dart';
import '../../pub/validator/compiled_dartdoc.dart';
import '../../pub/validator/dependency.dart';
import '../../pub/validator/directory.dart';
import '../../pub/validator/lib.dart';
import '../../pub/validator/license.dart';
import '../../pub/validator/name.dart';
import '../../pub/validator/pubspec_field.dart';
import '../../pub/validator/size.dart';
import '../../pub/validator/utf8_readme.dart';
import 'descriptor.dart' as d;
import 'test_pub.dart';

void expectNoValidationError(ValidatorCreator fn) {
  expect(schedulePackageValidation(fn), completion(pairOf(isEmpty, isEmpty)));
}

void expectValidationError(ValidatorCreator fn) {
  expect(schedulePackageValidation(fn),
      completion(pairOf(isNot(isEmpty), anything)));
}

void expectValidationWarning(ValidatorCreator fn) {
  expect(schedulePackageValidation(fn),
      completion(pairOf(isEmpty, isNot(isEmpty))));
}

expectDependencyValidationError(String error) {
  expect(schedulePackageValidation(dependency),
      completion(pairOf(someElement(contains(error)), isEmpty)));
}

expectDependencyValidationWarning(String warning) {
  expect(schedulePackageValidation(dependency),
      completion(pairOf(isEmpty, someElement(contains(warning)))));
}

Validator compiledDartdoc(Entrypoint entrypoint) =>
  new CompiledDartdocValidator(entrypoint);

Validator dependency(Entrypoint entrypoint) =>
  new DependencyValidator(entrypoint);

Validator directory(Entrypoint entrypoint) =>
  new DirectoryValidator(entrypoint);

Validator lib(Entrypoint entrypoint) => new LibValidator(entrypoint);

Validator license(Entrypoint entrypoint) => new LicenseValidator(entrypoint);

Validator name(Entrypoint entrypoint) => new NameValidator(entrypoint);

Validator pubspecField(Entrypoint entrypoint) =>
  new PubspecFieldValidator(entrypoint);

Function size(int size) {
  return (entrypoint) =>
      new SizeValidator(entrypoint, new Future.immediate(size));
}

Validator utf8Readme(Entrypoint entrypoint) =>
  new Utf8ReadmeValidator(entrypoint);

void scheduleNormalPackage() {
  d.validPackage.create();
}

/// Sets up a test package with dependency [dep] and mocks a server with
/// [hostedVersions] of the package available.
setUpDependency(Map dep, {List<String> hostedVersions}) {
  useMockClient(new MockClient((request) {
    expect(request.method, equals("GET"));
    expect(request.url.path, equals("/packages/foo.json"));

    if (hostedVersions == null) {
      return new Future.immediate(new http.Response("not found", 404));
    } else {
      return new Future.immediate(new http.Response(json.stringify({
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
  group('should consider a package valid if it', () {
    setUp(scheduleNormalPackage);

    integration('looks normal', () {
      d.dir(appPath, [d.libPubspec("test_pkg", "1.0.0")]).create();
      expectNoValidationError(dependency);
      expectNoValidationError(lib);
      expectNoValidationError(license);
      expectNoValidationError(name);
      expectNoValidationError(pubspecField);
    });

    integration('has a COPYING file', () {
      schedule(() => deleteEntry(path.join(sandboxDir, appPath, 'LICENSE')));
      d.file(path.join(appPath, 'COPYING'), '').create();
      expectNoValidationError(license);
    });

    integration('has a prefixed LICENSE file', () {
      schedule(() => deleteEntry(path.join(sandboxDir, appPath, 'LICENSE')));
      d.file(path.join(appPath, 'MIT_LICENSE'), '').create();
      expectNoValidationError(license);
    });

    integration('has a suffixed LICENSE file', () {
      schedule(() => deleteEntry(path.join(sandboxDir, appPath, 'LICENSE')));
      d.file(path.join(appPath, 'LICENSE.md'), '').create();
      expectNoValidationError(license);
    });

    integration('has "authors" instead of "author"', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg["authors"] = [pkg.remove("author")];
      d.dir(appPath, [d.pubspec(pkg)]).create();
      expectNoValidationError(pubspecField);
    });

    integration('has a badly-named library in lib/src', () {
      d.dir(appPath, [
        d.libPubspec("test_pkg", "1.0.0"),
        d.dir("lib", [
          d.file("test_pkg.dart", "int i = 1;"),
          d.dir("src", [d.file("8ball.dart", "int j = 2;")])
        ])
      ]).create();
      expectNoValidationError(name);
    });

    integration('has a non-Dart file in lib', () {
      d.dir(appPath, [
        d.libPubspec("test_pkg", "1.0.0"),
        d.dir("lib", [
          d.file("thing.txt", "woo hoo")
        ])
      ]).create();
      expectNoValidationError(lib);
    });

    integration('has a nested directory named "tools"', () {
      d.dir(appPath, [
        d.dir("foo", [d.dir("tools")])
      ]).create();
      expectNoValidationError(directory);
    });

    integration('is <= 10 MB', () {
      expectNoValidationError(size(100));
      expectNoValidationError(size(10 * math.pow(2, 20)));
    });

    integration('has most but not all files from compiling dartdoc', () {
      d.dir(appPath, [
        d.dir("doc-out", [
          d.file("nav.json", ""),
          d.file("index.html", ""),
          d.file("styles.css", ""),
          d.file("dart-logo-small.png", "")
        ])
      ]).create();
      expectNoValidationError(compiledDartdoc);
    });

    integration('has a non-primary readme with invalid utf-8', () {
      d.dir(appPath, [
        d.file("README", "Valid utf-8"),
        d.binaryFile("README.invalid", [192])
      ]).create();
      expectNoValidationError(utf8Readme);
    });
  });

  group('should consider a package invalid if it', () {
    setUp(scheduleNormalPackage);

    integration('is missing the "homepage" field', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg.remove("homepage");
      d.dir(appPath, [d.pubspec(pkg)]).create();

      expectValidationError(pubspecField);
    });

    integration('is missing the "description" field', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg.remove("description");
      d.dir(appPath, [d.pubspec(pkg)]).create();

      expectValidationError(pubspecField);
    });

    integration('is missing the "author" field', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg.remove("author");
      d.dir(appPath, [d.pubspec(pkg)]).create();

      expectValidationError(pubspecField);
    });

    integration('has a single author without an email', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg["author"] = "Nathan Weizenbaum";
      d.dir(appPath, [d.pubspec(pkg)]).create();

      expectValidationWarning(pubspecField);
    });

    integration('has one of several authors without an email', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg.remove("author");
      pkg["authors"] = [
        "Bob Nystrom <rnystrom@google.com>",
        "Nathan Weizenbaum",
        "John Messerly <jmesserly@google.com>"
      ];
      d.dir(appPath, [d.pubspec(pkg)]).create();

      expectValidationWarning(pubspecField);
    });

    integration('has a single author without a name', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg["author"] = "<nweiz@google.com>";
      d.dir(appPath, [d.pubspec(pkg)]).create();

      expectValidationWarning(pubspecField);
    });

    integration('has one of several authors without a name', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg.remove("author");
      pkg["authors"] = [
        "Bob Nystrom <rnystrom@google.com>",
        "<nweiz@google.com>",
        "John Messerly <jmesserly@google.com>"
      ];
      d.dir(appPath, [d.pubspec(pkg)]).create();

      expectValidationWarning(pubspecField);
    });

    integration('has no LICENSE file', () {
      schedule(() => deleteEntry(path.join(sandboxDir, appPath, 'LICENSE')));
      expectValidationError(license);
    });

    integration('has an empty package name', () {
      d.dir(appPath, [d.libPubspec("", "1.0.0")]).create();
      expectValidationError(name);
    });

    integration('has a package name with an invalid character', () {
      d.dir(appPath, [d.libPubspec("test-pkg", "1.0.0")]).create();
      expectValidationError(name);
    });

    integration('has a package name that begins with a number', () {
      d.dir(appPath, [d.libPubspec("8ball", "1.0.0")]).create();
      expectValidationError(name);
    });

    integration('has a package name that contains upper-case letters', () {
      d.dir(appPath, [d.libPubspec("TestPkg", "1.0.0")]).create();
      expectValidationWarning(name);
    });

    integration('has a package name that is a Dart reserved word', () {
      d.dir(appPath, [d.libPubspec("final", "1.0.0")]).create();
      expectValidationError(name);
    });

    integration('has a library name with an invalid character', () {
      d.dir(appPath, [
        d.libPubspec("test_pkg", "1.0.0"),
        d.dir("lib", [d.file("test-pkg.dart", "int i = 0;")])
      ]).create();
      expectValidationWarning(name);
    });

    integration('has a library name that begins with a number', () {
      d.dir(appPath, [
        d.libPubspec("test_pkg", "1.0.0"),
        d.dir("lib", [d.file("8ball.dart", "int i = 0;")])
      ]).create();
      expectValidationWarning(name);
    });

    integration('has a library name that contains upper-case letters', () {
      d.dir(appPath, [
        d.libPubspec("test_pkg", "1.0.0"),
        d.dir("lib", [d.file("TestPkg.dart", "int i = 0;")])
      ]).create();
      expectValidationWarning(name);
    });

    integration('has a library name that is a Dart reserved word', () {
      d.dir(appPath, [
        d.libPubspec("test_pkg", "1.0.0"),
        d.dir("lib", [d.file("for.dart", "int i = 0;")])
      ]).create();
      expectValidationWarning(name);
    });

    integration('has a single library named differently than the package', () {
      schedule(() =>
          deleteEntry(path.join(sandboxDir, appPath, "lib", "test_pkg.dart")));
      d.dir(appPath, [
        d.dir("lib", [d.file("best_pkg.dart", "int i = 0;")])
      ]).create();
      expectValidationWarning(name);
    });

    integration('has no lib directory', () {
      schedule(() => deleteEntry(path.join(sandboxDir, appPath, "lib")));
      expectValidationError(lib);
    });

    integration('has an empty lib directory', () {
      schedule(() =>
          deleteEntry(path.join(sandboxDir, appPath, "lib", "test_pkg.dart")));
      expectValidationError(lib);
    });

    integration('has a lib directory containing only src', () {
      schedule(() =>
          deleteEntry(path.join(sandboxDir, appPath, "lib", "test_pkg.dart")));
      d.dir(appPath, [
        d.dir("lib", [
          d.dir("src", [d.file("test_pkg.dart", "int i = 0;")])
        ])
      ]).create();
      expectValidationError(lib);
    });

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

    group('has a top-level directory named', () {
      setUp(scheduleNormalPackage);

      var names = ["tools", "tests", "docs", "examples", "sample", "samples"];
      for (var name in names) {
        integration('"$name"', () {
          d.dir(appPath, [d.dir(name)]).create();
          expectValidationWarning(directory);
        });
      }
    });

    integration('is more than 10 MB', () {
      expectValidationError(size(10 * math.pow(2, 20) + 1));
    });

    integration('contains compiled dartdoc', () {
      d.dir(appPath, [
        d.dir('doc-out', [
          d.file('nav.json', ''),
          d.file('index.html', ''),
          d.file('styles.css', ''),
          d.file('dart-logo-small.png', ''),
          d.file('client-live-nav.js', '')
        ])
      ]).create();

      expectValidationWarning(compiledDartdoc);
    });

    integration('has a README with invalid utf-8', () {
      d.dir(appPath, [
        d.binaryFile("README", [192])
      ]).create();
      expectValidationWarning(utf8Readme);
    });
  });
}
