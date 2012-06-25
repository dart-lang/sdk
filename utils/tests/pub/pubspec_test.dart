// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('pubspec_test');

#import('../../../lib/unittest/unittest.dart');
#import('../../pub/pubspec.dart');
#import('../../pub/source.dart');
#import('../../pub/source_registry.dart');
#import('../../pub/utils.dart');
#import('../../pub/version.dart');

class MockSource extends Source {
  final String name = "mock";
  final bool shouldCache = false;
  void validateDescription(description) {
    if (description != 'ok') throw new FormatException('Bad');
  }
}

main() {
  group('Pubspec', () {
    group('parse()', () {
      test("allows a version constraint for dependencies", () {
        var sources = new SourceRegistry();
        sources.register(new MockSource());

        var pubspec = new Pubspec.parse('''
dependencies:
  foo:
    mock: ok
    version: ">=1.2.3 <3.4.5"
''', sources);

        var foo = pubspec.dependencies[0];
        expect(foo.name, equals('foo'));
        expect(foo.constraint.allows(new Version(1, 2, 3)));
        expect(foo.constraint.allows(new Version(1, 2, 5)));
        expect(!foo.constraint.allows(new Version(3, 4, 5)));
      });

      test("throws if the description isn't valid", () {
        var sources = new SourceRegistry();
        sources.register(new MockSource());

        throwsBadFormat(() {
        new Pubspec.parse('''
dependencies:
  foo:
    mock: bad
''', sources);
        });
      });
    });
  });
}

throwsBadFormat(function) {
  expectThrow(function, (e) => e is FormatException);
}
