// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('source_test');

#import('../../../lib/unittest/unittest.dart');
#import('../../pub/pubspec.dart');
#import('../../pub/source.dart');
#import('../../pub/source_registry.dart');
#import('../../pub/utils.dart');

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
