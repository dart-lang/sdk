// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('version_test');

#import('../../../lib/unittest/unittest.dart');
#import('../../pub/utils.dart');
#import('../../pub/version.dart');

main() {
  group('Version', () {
    test('none', () {
      expect(Version.none.toString()).equals('0.0.0');
    });

    group('constructor', () {
      test('throws on negative numbers', () {
        throwsIllegalArg(() => new Version(-1, 1, 1));
        throwsIllegalArg(() => new Version(1, -1, 1));
        throwsIllegalArg(() => new Version(1, 1, -1));
      });
    });

    group('comparison', () {
      // A correctly sorted list of versions.
      var versions = [
        '1.0.0-alpha',
        '1.0.0-alpha.1',
        '1.0.0-beta.2',
        '1.0.0-beta.11',
        '1.0.0-rc.1',
        '1.0.0-rc.1+build.1',
        '1.0.0',
        '1.0.0+0.3.7',
        '1.3.7+build',
        '1.3.7+build.2.b8f12d7',
        '1.3.7+build.11.e0f985a',
        '2.0.0',
        '2.1.0',
        '2.2.0',
        '2.11.0',
        '2.11.1'
      ];

      test('compareTo()', () {
        // Ensure that every pair of versions compares in the order that it
        // appears in the list.
        for (var i = 0; i < versions.length; i++) {
          for (var j = 0; j < versions.length; j++) {
            var a = new Version.parse(versions[i]);
            var b = new Version.parse(versions[j]);
            var expectation = i.compareTo(j);
            expect(a.compareTo(b)).equals(expectation);
          }
        }
      });

      test('operators', () {
        for (var i = 0; i < versions.length; i++) {
          for (var j = 0; j < versions.length; j++) {
            var a = new Version.parse(versions[i]);
            var b = new Version.parse(versions[j]);
            expect(a < b).equals(i < j);
            expect(a > b).equals(i > j);
            expect(a <= b).equals(i <= j);
            expect(a >= b).equals(i >= j);
            expect(a == b).equals(i == j);
            expect(a != b).equals(i != j);
          }
        }
      });
    });

    test('allows()', () {
      expect(new Version.parse('1.2.3').allows(
          new Version.parse('1.2.3'))).isTrue();
      expect(new Version.parse('1.2.3').allows(
          new Version.parse('1.1.4'))).isFalse();
      expect(new Version.parse('1.2.3').allows(
          new Version.parse('1.2.4'))).isFalse();
    });

    test('parse()', () {
      expect(new Version.parse('0.0.0')).equals(new Version(0, 0, 0));
      expect(new Version.parse('12.34.56')).equals(new Version(12, 34, 56));

      expect(new Version.parse('1.2.3-alpha.1')).equals(
          new Version(1, 2, 3, pre: 'alpha.1'));
      expect(new Version.parse('1.2.3-x.7.z-92')).equals(
          new Version(1, 2, 3, pre: 'x.7.z-92'));

      expect(new Version.parse('1.2.3+build.1')).equals(
          new Version(1, 2, 3, build: 'build.1'));
      expect(new Version.parse('1.2.3+x.7.z-92')).equals(
          new Version(1, 2, 3, build: 'x.7.z-92'));

      expect(new Version.parse('1.0.0-rc-1+build-1')).equals(
          new Version(1, 0, 0, pre: 'rc-1', build: 'build-1'));

      throwsBadFormat(() => new Version.parse('1.0'));
      throwsBadFormat(() => new Version.parse('1.2.3.4'));
      throwsBadFormat(() => new Version.parse('1234'));
      throwsBadFormat(() => new Version.parse('-2.3.4'));
      throwsBadFormat(() => new Version.parse('1.3-pre'));
      throwsBadFormat(() => new Version.parse('1.3+build'));
      throwsBadFormat(() => new Version.parse('1.3+bu?!3ild'));
    });

    test('toString()', () {
      expect(new Version(0, 0, 0).toString()).equals('0.0.0');
      expect(new Version(12, 34, 56).toString()).equals('12.34.56');

      expect(new Version(1, 2, 3, pre: 'alpha.1').toString()).equals(
          '1.2.3-alpha.1');
      expect(new Version(1, 2, 3, pre: 'x.7.z-92').toString()).equals(
          '1.2.3-x.7.z-92');

      expect(new Version(1, 2, 3, build: 'build.1').toString()).equals(
          '1.2.3+build.1');
      expect(new Version(1, 2, 3, pre: 'pre', build: 'bui').toString()).equals(
          '1.2.3-pre+bui');
    });
  });

  group('VersionRange', () {
    group('constructor', () {
      test('takes a min and max', () {
        var min = new Version.parse('1.2.3');
        var max = new Version.parse('1.3.5');
        var range = new VersionRange(min, max);
        expect(range.min).equals(min);
        expect(range.max).equals(max);
      });

      test('allows omitting max', () {
        var min = new Version.parse('1.2.3');
        var range = new VersionRange(min);
        expect(range.min).equals(min);
        expect(range.max).isNull();
      });

      test('allows omitting min and max', () {
        var range = new VersionRange();
        expect(range.min).isNull();
        expect(range.max).isNull();
      });

      test('throws if min > max', () {
        var min = new Version.parse('1.2.3');
        var max = new Version.parse('1.0.0');

        throwsIllegalArg(() => new VersionRange(min, max));
      });
    });

    group('allows()', () {
      test('version must be min or greater', () {
        var range = new VersionRange(
            new Version.parse('1.2.3'), new Version.parse('2.3.4'));

        expect(range.allows(new Version.parse('1.2.2'))).isFalse();
        expect(range.allows(new Version.parse('1.2.3'))).isTrue();
        expect(range.allows(new Version.parse('1.3.3'))).isTrue();
        expect(range.allows(new Version.parse('2.3.3'))).isTrue();
      });

      test('version must be less than max', () {
        var range = new VersionRange(
            new Version.parse('1.2.3'), new Version.parse('2.3.4'));

        expect(range.allows(new Version.parse('2.3.3'))).isTrue();
        expect(range.allows(new Version.parse('2.3.4'))).isFalse();
        expect(range.allows(new Version.parse('2.4.3'))).isFalse();
      });

      test('has no min if one was not set', () {
        var range = new VersionRange(max: new Version.parse('1.2.3'));

        expect(range.allows(new Version.parse('0.0.0'))).isTrue();
        expect(range.allows(new Version.parse('1.2.3'))).isFalse();
      });

      test('has no max if one was not set', () {
        var range = new VersionRange(new Version.parse('1.2.3'));

        expect(range.allows(new Version.parse('1.2.3'))).isTrue();
        expect(range.allows(new Version.parse('1.3.3'))).isTrue();
        expect(range.allows(new Version.parse('999.3.3'))).isTrue();
      });

      test('allows any version if there is no min or max', () {
        var range = new VersionRange();

        expect(range.allows(new Version.parse('0.0.0'))).isTrue();
        expect(range.allows(new Version.parse('999.99.9'))).isTrue();
      });
    });
  });
}

throwsIllegalArg(function) {
  expectThrow(function, (e) => e is IllegalArgumentException);
}

throwsBadFormat(function) {
  expectThrow(function, (e) => e is FormatException);
}
