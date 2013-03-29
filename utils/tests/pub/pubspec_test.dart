// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pubspec_test;

import 'package:unittest/unittest.dart';

import '../../pub/pubspec.dart';
import '../../pub/source.dart';
import '../../pub/source_registry.dart';
import '../../pub/utils.dart';
import '../../pub/version.dart';
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

    expectFormatError(String pubspec) {
      expect(() => new Pubspec.parse(null, pubspec, sources),
          throwsFormatException);
    }

    test("allows a version constraint for dependencies", () {
      var pubspec = new Pubspec.parse(null, '''
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
      var pubspec = new Pubspec.parse(null, '''
dependencies:
''', sources);

      expect(pubspec.dependencies, isEmpty);
    });

    test("allows a version constraint for dev dependencies", () {
      var pubspec = new Pubspec.parse(null, '''
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
      var pubspec = new Pubspec.parse(null, '''
dev_dependencies:
''', sources);

      expect(pubspec.devDependencies, isEmpty);
    });

    test("throws if a package is in dependencies and dev_dependencies", () {
      expectFormatError('''
dependencies:
  foo:
    mock: ok
dev_dependencies:
  foo:
    mock: ok
''');
    });

    test("throws if the description isn't valid", () {
      expectFormatError('''
dependencies:
  foo:
    mock: bad
''');
    });

    test("throws if 'name' is not a string", () {
      expectFormatError('name: [not, a, string]');
    });

    test("throws if 'homepage' is not a string", () {
      expectFormatError('homepage:');
      expectFormatError('homepage: [not, a, string]');
    });

    test("throws if 'homepage' doesn't have an HTTP scheme", () {
      new Pubspec.parse(null, 'homepage: http://ok.com', sources);
      new Pubspec.parse(null, 'homepage: https://also-ok.com', sources);

      expectFormatError('homepage: ftp://badscheme.com');
      expectFormatError('homepage: javascript:alert("!!!")');
      expectFormatError('homepage: data:image/png;base64,somedata');
      expectFormatError('homepage: no-scheme.com');
    });

    test("throws if 'documentation' is not a string", () {
      expectFormatError('documentation:');
      expectFormatError('documentation: [not, a, string]');
    });

    test("throws if 'documentation' doesn't have an HTTP scheme", () {
      new Pubspec.parse(null, 'documentation: http://ok.com', sources);
      new Pubspec.parse(null, 'documentation: https://also-ok.com', sources);

      expectFormatError('documentation: ftp://badscheme.com');
      expectFormatError('documentation: javascript:alert("!!!")');
      expectFormatError('documentation: data:image/png;base64,somedata');
      expectFormatError('documentation: no-scheme.com');
    });

    test("throws if 'authors' is not a string or a list of strings", () {
      new Pubspec.parse(null, 'authors: ok fine', sources);
      new Pubspec.parse(null, 'authors: [also, ok, fine]', sources);

      expectFormatError('authors: 123');
      expectFormatError('authors: {not: {a: string}}');
      expectFormatError('authors: [ok, {not: ok}]');
    });

    test("throws if 'author' is not a string", () {
      new Pubspec.parse(null, 'author: ok fine', sources);

      expectFormatError('author: 123');
      expectFormatError('author: {not: {a: string}}');
      expectFormatError('author: [not, ok]');
    });

    test("throws if both 'author' and 'authors' are present", () {
      expectFormatError('{author: abe, authors: ted}');
    });

    test("allows comment-only files", () {
      var pubspec = new Pubspec.parse(null, '''
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
        var pubspec = new Pubspec.parse(null, '', sources);
        expect(pubspec.environment.sdkVersion, equals(VersionConstraint.any));
      });

      test("allows an empty environment map", () {
        var pubspec = new Pubspec.parse(null, '''
environment:
''', sources);
        expect(pubspec.environment.sdkVersion, equals(VersionConstraint.any));
      });

      test("throws if the environment value isn't a map", () {
        expectFormatError('''
environment: []
''');
      });

      test("allows a version constraint for the sdk", () {
        var pubspec = new Pubspec.parse(null, '''
environment:
  sdk: ">=1.2.3 <2.3.4"
''', sources);
        expect(pubspec.environment.sdkVersion,
            equals(new VersionConstraint.parse(">=1.2.3 <2.3.4")));
      });

      test("throws if the sdk isn't a string", () {
        expectFormatError('''
environment:
  sdk: []
''');
      });

      test("throws if the sdk isn't a valid version constraint", () {
        expectFormatError('''
environment:
  sdk: "oopies"
''');
      });
    });
  });
}
