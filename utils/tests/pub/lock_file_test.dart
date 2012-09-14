// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('lock_file_test');

#import('../../../pkg/unittest/lib/unittest.dart');
#import('../../pub/lock_file.dart');
#import('../../pub/package.dart');
#import('../../pub/source.dart');
#import('../../pub/source_registry.dart');
#import('../../pub/utils.dart');
#import('../../pub/version.dart');
#import('../../pub/yaml/yaml.dart');

class MockSource extends Source {
  final String name = 'mock';
  final bool shouldCache = false;

  void validateDescription(String description, [bool fromLockFile=false]) {
    description.endsWith(' desc');
  }

  String packageName(String description) {
    // Strip off ' desc'.
    return description.substring(0, description.length - 5);
  }
}

main() {
  var sources = new SourceRegistry();
  var mockSource = new MockSource();
  sources.register(mockSource);

  group('LockFile', () {
    group('parse()', () {
      test('returns an empty lockfile if the contents are empty', () {
        var lockFile = new LockFile.parse('', sources);
        expect(lockFile.packages.length, equals(0));
      });

      test('returns an empty lockfile if the contents are whitespace', () {
        var lockFile = new LockFile.parse('  \t\n  ', sources);
        expect(lockFile.packages.length, equals(0));
      });

      test('parses a series of package descriptions', () {
        var lockFile = new LockFile.parse('''
packages:
  bar:
    version: 1.2.3
    source: mock
    description: bar desc
  foo:
    version: 2.3.4
    source: mock
    description: foo desc
''', sources);

        expect(lockFile.packages.length, equals(2));

        var bar = lockFile.packages['bar'];
        expect(bar.name, equals('bar'));
        expect(bar.version, equals(new Version(1, 2, 3)));
        expect(bar.source, equals(mockSource));
        expect(bar.description, equals('bar desc'));

        var foo = lockFile.packages['foo'];
        expect(foo.name, equals('foo'));
        expect(foo.version, equals(new Version(2, 3, 4)));
        expect(foo.source, equals(mockSource));
        expect(foo.description, equals('foo desc'));
      });

      test("throws if the version is missing", () {
        expect(() {
          new LockFile.parse('''
packages:
  foo:
    source: mock
    description: foo desc
''', sources);
        }, throwsFormatException);
      });

      test("throws if the version is invalid", () {
        expect(() {
          new LockFile.parse('''
packages:
  foo:
    version: vorpal
    source: mock
    description: foo desc
''', sources);
        }, throwsFormatException);
      });

      test("throws if the source is missing", () {
        expect(() {
          new LockFile.parse('''
packages:
  foo:
    version: 1.2.3
    description: foo desc
''', sources);
        }, throwsFormatException);
      });

      test("throws if the source is unknown", () {
        expect(() {
          new LockFile.parse('''
packages:
  foo:
    version: 1.2.3
    source: notreal
    description: foo desc
''', sources);
        }, throwsFormatException);
      });

      test("throws if the description is missing", () {
        expect(() {
          new LockFile.parse('''
packages:
  foo:
    version: 1.2.3
    source: mock
''', sources);
        }, throwsFormatException);
      });

      test("throws if the description is invalid", () {
        expect(() {
          new LockFile.parse('''
packages:
  foo:
    version: 1.2.3
    source: mock
    description: foo desc is bad
''', sources);
        }, throwsFormatException);
      });

      test("throws if the source name doesn't match the given name", () {
        expect(() {
          new LockFile.parse('''
packages:
  foo:
    version: 1.2.3
    source: mock
    description: notfoo desc
''', sources);
        }, throwsFormatException);
      });

      test("ignores extra stuff in file", () {
        var lockFile = new LockFile.parse('''
extra:
  some: stuff
packages:
  foo:
    bonus: not used
    version: 1.2.3
    source: mock
    description: foo desc
''', sources);
      });
    });

    group('serialize()', () {
      test('dumps the lockfile to YAML', () {
        var lockfile = new LockFile.empty();
        lockfile.packages['foo'] =
          new PackageId(mockSource, new Version.parse('1.2.3'), 'foo desc');
        lockfile.packages['bar'] =
          new PackageId(mockSource, new Version.parse('3.2.1'), 'bar desc');

        expect(loadYaml(lockfile.serialize()), equals({
          'packages': {
            'foo': {
              'version': '1.2.3',
              'source': 'mock',
              'description': 'foo desc'
            },
            'bar': {
              'version': '3.2.1',
              'source': 'mock',
              'description': 'bar desc'
            }
          }
        }));
      });
    });
  });
}
