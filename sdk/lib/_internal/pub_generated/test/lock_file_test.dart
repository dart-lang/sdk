library lock_file_test;
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:yaml/yaml.dart';
import '../lib/src/lock_file.dart';
import '../lib/src/package.dart';
import '../lib/src/pubspec.dart';
import '../lib/src/source.dart';
import '../lib/src/source_registry.dart';
import '../lib/src/version.dart';
import 'test_pub.dart';
class MockSource extends Source {
  final String name = 'mock';
  Future<Pubspec> doDescribe(PackageId id) =>
      throw new UnsupportedError("Cannot describe mock packages.");
  Future get(PackageId id, String symlink) =>
      throw new UnsupportedError("Cannot get a mock package.");
  Future<String> getDirectory(PackageId id) =>
      throw new UnsupportedError("Cannot get the directory for mock packages.");
  dynamic parseDescription(String filePath, String description,
      {bool fromLockFile: false}) {
    if (!description.endsWith(' desc')) throw new FormatException();
    return description;
  }
  bool descriptionsEqual(description1, description2) =>
      description1 == description2;
  String packageName(String description) {
    return description.substring(0, description.length - 5);
  }
}
main() {
  initConfig();
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
        expect(bar.source, equals(mockSource.name));
        expect(bar.description, equals('bar desc'));
        var foo = lockFile.packages['foo'];
        expect(foo.name, equals('foo'));
        expect(foo.version, equals(new Version(2, 3, 4)));
        expect(foo.source, equals(mockSource.name));
        expect(foo.description, equals('foo desc'));
      });
      test("allows an unknown source", () {
        var lockFile = new LockFile.parse('''
packages:
  foo:
    source: bad
    version: 1.2.3
    description: foo desc
''', sources);
        var foo = lockFile.packages['foo'];
        expect(foo.source, equals('bad'));
      });
      test("allows an empty dependency map", () {
        var lockFile = new LockFile.parse('''
packages:
''', sources);
        expect(lockFile.packages, isEmpty);
      });
      test("throws if the top level is not a map", () {
        expect(() {
          new LockFile.parse('''
not a map
''', sources);
        }, throwsFormatException);
      });
      test("throws if the contents of 'packages' is not a map", () {
        expect(() {
          new LockFile.parse('''
packages: not a map
''', sources);
        }, throwsFormatException);
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
      var lockfile;
      setUp(() {
        lockfile = new LockFile.empty();
      });
      test('dumps the lockfile to YAML', () {
        lockfile.packages['foo'] =
            new PackageId('foo', mockSource.name, new Version.parse('1.2.3'), 'foo desc');
        lockfile.packages['bar'] =
            new PackageId('bar', mockSource.name, new Version.parse('3.2.1'), 'bar desc');
        expect(loadYaml(lockfile.serialize(null, sources)), equals({
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
