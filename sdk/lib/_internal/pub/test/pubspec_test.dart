// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pubspec_test;

import 'package:unittest/unittest.dart';

import '../lib/src/pubspec.dart';
import '../lib/src/source.dart';
import '../lib/src/source_registry.dart';
import '../lib/src/version.dart';
import 'test_pub.dart';

class MockSource extends Source {
  final String name = "mock";
  final bool shouldCache = false;
  dynamic parseDescription(String filePath, description,
                           {bool fromLockFile: false}) {
    if (description != 'ok') throw new FormatException('Bad');
    return description;
  }
  String packageName(description) => 'foo';
}

main() {
  initConfig();
  group('parse()', () {
    var sources = new SourceRegistry();
    sources.register(new MockSource());

    var throwsPubspecException =
      throwsA(new isInstanceOf<PubspecException>('PubspecException'));

    expectPubspecException(String contents, fn(Pubspec pubspec)) {
      var pubspec = new Pubspec.parse(contents, sources);
      expect(() => fn(pubspec), throwsPubspecException);
    }

    test("doesn't eagerly throw an error for an invalid field", () {
      // Shouldn't throw an error.
      new Pubspec.parse('version: not a semver', sources);
    });

    test("eagerly throws an error if the pubspec name doesn't match the "
        "expected name", () {
      expect(() => new Pubspec.parse("name: foo", sources, expectedName: 'bar'),
          throwsPubspecException);
    });

    test("eagerly throws an error if the pubspec doesn't have a name and an "
        "expected name is passed", () {
      expect(() => new Pubspec.parse("{}", sources, expectedName: 'bar'),
          throwsPubspecException);
    });

    test("allows a version constraint for dependencies", () {
      var pubspec = new Pubspec.parse('''
dependencies:
  foo:
    mock: ok
    version: ">=1.2.3 <3.4.5"
''', sources);

      var foo = pubspec.dependencies[0];
      expect(foo.name, equals('foo'));
      expect(foo.constraint.allows(new Version(1, 2, 3)), isTrue);
      expect(foo.constraint.allows(new Version(1, 2, 5)), isTrue);
      expect(foo.constraint.allows(new Version(3, 4, 5)), isFalse);
    });

    test("allows an empty dependencies map", () {
      var pubspec = new Pubspec.parse('''
dependencies:
''', sources);

      expect(pubspec.dependencies, isEmpty);
    });

    test("allows a version constraint for dev dependencies", () {
      var pubspec = new Pubspec.parse('''
dev_dependencies:
  foo:
    mock: ok
    version: ">=1.2.3 <3.4.5"
''', sources);

      var foo = pubspec.devDependencies[0];
      expect(foo.name, equals('foo'));
      expect(foo.constraint.allows(new Version(1, 2, 3)), isTrue);
      expect(foo.constraint.allows(new Version(1, 2, 5)), isTrue);
      expect(foo.constraint.allows(new Version(3, 4, 5)), isFalse);
    });

    test("allows an empty dev dependencies map", () {
      var pubspec = new Pubspec.parse('''
dev_dependencies:
''', sources);

      expect(pubspec.devDependencies, isEmpty);
    });

    test("allows an unknown source", () {
      var pubspec = new Pubspec.parse('''
dependencies:
  foo:
    unknown: blah
''', sources);

      var foo = pubspec.dependencies[0];
      expect(foo.name, equals('foo'));
      expect(foo.source, equals('unknown'));
    });

    test("throws if a package is in dependencies and dev_dependencies", () {
      var contents = '''
dependencies:
  foo:
    mock: ok
dev_dependencies:
  foo:
    mock: ok
''';
      expectPubspecException(contents, (pubspec) => pubspec.dependencies);
      expectPubspecException(contents, (pubspec) => pubspec.devDependencies);
    });

    test("throws if it dependes on itself", () {
      expectPubspecException('''
name: myapp
dependencies:
  myapp:
    mock: ok
''', (pubspec) => pubspec.dependencies);
    });

    test("throws if it has a dev dependency on itself", () {
      expectPubspecException('''
name: myapp
dev_dependencies:
  myapp:
    mock: ok
''', (pubspec) => pubspec.devDependencies);
    });

    test("throws if the description isn't valid", () {
      expectPubspecException('''
dependencies:
  foo:
    mock: bad
''', (pubspec) => pubspec.dependencies);
    });

    test("throws if dependency version is not a string", () {
      expectPubspecException('''
dependencies:
  foo:
    mock: ok
    version: 1.2
''', (pubspec) => pubspec.dependencies);
    });

    test("throws if version is not a version constraint", () {
      expectPubspecException('''
dependencies:
  foo:
    mock: ok
    version: not constraint
''', (pubspec) => pubspec.dependencies);
    });

    test("throws if 'name' is not a string", () {
      expectPubspecException('name: [not, a, string]',
          (pubspec) => pubspec.name);
    });

    test("throws if version is not a string", () {
      expectPubspecException('version: 1.0', (pubspec) => pubspec.version);
    });

    test("throws if version is not a version", () {
      expectPubspecException('version: not version',
          (pubspec) => pubspec.version);
    });

    test("throws if a transformer isn't a string or map", () {
      expectPubspecException('transformers: 12',
          (pubspec) => pubspec.transformers);
      expectPubspecException('transformers: [12]',
          (pubspec) => pubspec.transformers);
    });

    test("throws if a transformer's configuration isn't a map", () {
      expectPubspecException('transformers: {pkg: 12}',
          (pubspec) => pubspec.transformers);
    });

    test("allows comment-only files", () {
      var pubspec = new Pubspec.parse('''
# No external dependencies yet
# Including for completeness
# ...and hoping the spec expands to include details about author, version, etc
# See http://www.dartlang.org/docs/pub-package-manager/ for details
''', sources);
      expect(pubspec.version, equals(Version.none));
      expect(pubspec.dependencies, isEmpty);
    });

    group("environment", () {
      test("defaults to any SDK constraint if environment is omitted", () {
        var pubspec = new Pubspec.parse('', sources);
        expect(pubspec.environment.sdkVersion, equals(VersionConstraint.any));
      });

      test("allows an empty environment map", () {
        var pubspec = new Pubspec.parse('''
environment:
''', sources);
        expect(pubspec.environment.sdkVersion, equals(VersionConstraint.any));
      });

      test("throws if the environment value isn't a map", () {
        expectPubspecException('environment: []',
            (pubspec) => pubspec.environment);
      });

      test("allows a version constraint for the sdk", () {
        var pubspec = new Pubspec.parse('''
environment:
  sdk: ">=1.2.3 <2.3.4"
''', sources);
        expect(pubspec.environment.sdkVersion,
            equals(new VersionConstraint.parse(">=1.2.3 <2.3.4")));
      });

      test("throws if the sdk isn't a string", () {
        expectPubspecException('environment: {sdk: []}',
            (pubspec) => pubspec.environment);
        expectPubspecException('environment: {sdk: 1.0}',
            (pubspec) => pubspec.environment);
      });

      test("throws if the sdk isn't a valid version constraint", () {
        expectPubspecException('environment: {sdk: "oopies"}',
            (pubspec) => pubspec.environment);
      });
    });
  });
}
