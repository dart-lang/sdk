// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('version_test');

#import('../../../pkg/unittest/unittest.dart');
#import('../../pub/utils.dart');
#import('../../pub/version.dart');

main() {
  final v123 = new Version.parse('1.2.3');
  final v114 = new Version.parse('1.1.4');
  final v124 = new Version.parse('1.2.4');
  final v200 = new Version.parse('2.0.0');
  final v234 = new Version.parse('2.3.4');
  final v250 = new Version.parse('2.5.0');
  final v300 = new Version.parse('3.0.0');

  group('Version', () {
    test('none', () {
      expect(Version.none.toString(), equals('0.0.0'));
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
            expect(a.compareTo(b), equals(expectation));
          }
        }
      });

      test('operators', () {
        for (var i = 0; i < versions.length; i++) {
          for (var j = 0; j < versions.length; j++) {
            var a = new Version.parse(versions[i]);
            var b = new Version.parse(versions[j]);
            expect(a < b, equals(i < j));
            expect(a > b, equals(i > j));
            expect(a <= b, equals(i <= j));
            expect(a >= b, equals(i >= j));
            expect(a == b, equals(i == j));
            expect(a != b, equals(i != j));
          }
        }
      });
    });

    test('allows()', () {
      expect(v123.allows(v123));
      expect(!v123.allows(v114));
      expect(!v123.allows(v124));
    });

    test('intersect()', () {
      // Intersecting the same version returns the version.
      expect(v123.intersect(v123), equals(v123));

      // Intersecting a different version allows no versions.
      expect(v123.intersect(v114).isEmpty);

      // Intersecting a range returns the version if the range allows it.
      expect(v123.intersect(new VersionRange(v114, v124)), equals(v123));

      // Intersecting a range allows no versions if the range doesn't allow it.
      expect(v114.intersect(new VersionRange(v123, v124)).isEmpty);
    });

    test('isEmpty', () {
      expect(!v123.isEmpty);
    });

    test('parse()', () {
      expect(new Version.parse('0.0.0'), equals(new Version(0, 0, 0)));
      expect(new Version.parse('12.34.56'), equals(new Version(12, 34, 56)));

      expect(new Version.parse('1.2.3-alpha.1'), equals(
          new Version(1, 2, 3, pre: 'alpha.1')));
      expect(new Version.parse('1.2.3-x.7.z-92'), equals(
          new Version(1, 2, 3, pre: 'x.7.z-92')));

      expect(new Version.parse('1.2.3+build.1'), equals(
          new Version(1, 2, 3, build: 'build.1')));
      expect(new Version.parse('1.2.3+x.7.z-92'), equals(
          new Version(1, 2, 3, build: 'x.7.z-92')));

      expect(new Version.parse('1.0.0-rc-1+build-1'), equals(
          new Version(1, 0, 0, pre: 'rc-1', build: 'build-1')));

      expect(() => new Version.parse('1.0'), throwsFormatException);
      expect(() => new Version.parse('1.2.3.4'), throwsFormatException);
      expect(() => new Version.parse('1234'), throwsFormatException);
      expect(() => new Version.parse('-2.3.4'), throwsFormatException);
      expect(() => new Version.parse('1.3-pre'), throwsFormatException);
      expect(() => new Version.parse('1.3+build'), throwsFormatException);
      expect(() => new Version.parse('1.3+bu?!3ild'), throwsFormatException);
    });

    test('toString()', () {
      expect(new Version(0, 0, 0).toString(), equals('0.0.0'));
      expect(new Version(12, 34, 56).toString(), equals('12.34.56'));

      expect(new Version(1, 2, 3, pre: 'alpha.1').toString(), equals(
          '1.2.3-alpha.1'));
      expect(new Version(1, 2, 3, pre: 'x.7.z-92').toString(), equals(
          '1.2.3-x.7.z-92'));

      expect(new Version(1, 2, 3, build: 'build.1').toString(), equals(
          '1.2.3+build.1'));
      expect(new Version(1, 2, 3, pre: 'pre', build: 'bui').toString(), equals(
          '1.2.3-pre+bui'));
    });
  });

  group('VersionRange', () {
    group('constructor', () {
      test('takes a min and max', () {
        var range = new VersionRange(v123, v124);
        expect(range.min, equals(v123));
        expect(range.max, equals(v124));
      });

      test('allows omitting max', () {
        var range = new VersionRange(v123);
        expect(range.min, equals(v123));
        expect(range.max, isNull);
      });

      test('allows omitting min and max', () {
        var range = new VersionRange();
        expect(range.min, isNull);
        expect(range.max, isNull);
      });

      test('takes includeMin', () {
        var range = new VersionRange(min: v123, includeMin: true);
        expect(range.includeMin);
      });

      test('includeMin defaults to false if omitted', () {
        var range = new VersionRange(min: v123);
        expect(range.includeMin, isFalse);
      });

      test('takes includeMax', () {
        var range = new VersionRange(max: v123, includeMax: true);
        expect(range.includeMax);
      });

      test('includeMax defaults to false if omitted', () {
        var range = new VersionRange(max: v123);
        expect(range.includeMax, isFalse);
      });

      test('throws if min > max', () {
        throwsIllegalArg(() => new VersionRange(v124, v123));
      });
    });

    group('allows()', () {
      test('version must be greater than min', () {
        var range = new VersionRange(v123, v234);

        expect(!range.allows(new Version.parse('1.2.2')));
        expect(!range.allows(new Version.parse('1.2.3')));
        expect(range.allows(new Version.parse('1.3.3')));
        expect(range.allows(new Version.parse('2.3.3')));
      });

      test('version must be min or greater if includeMin', () {
        var range = new VersionRange(v123, v234, includeMin: true);

        expect(!range.allows(new Version.parse('1.2.2')));
        expect(range.allows(new Version.parse('1.2.3')));
        expect(range.allows(new Version.parse('1.3.3')));
        expect(range.allows(new Version.parse('2.3.3')));
      });

      test('version must be less than max', () {
        var range = new VersionRange(v123, v234);

        expect(range.allows(new Version.parse('2.3.3')));
        expect(!range.allows(new Version.parse('2.3.4')));
        expect(!range.allows(new Version.parse('2.4.3')));
      });

      test('version must be max or less if includeMax', () {
        var range = new VersionRange(v123, v234, includeMax: true);

        expect(range.allows(new Version.parse('2.3.3')));
        expect(range.allows(new Version.parse('2.3.4')));
        expect(!range.allows(new Version.parse('2.4.3')));
      });

      test('has no min if one was not set', () {
        var range = new VersionRange(max: v123);

        expect(range.allows(new Version.parse('0.0.0')));
        expect(!range.allows(new Version.parse('1.2.3')));
      });

      test('has no max if one was not set', () {
        var range = new VersionRange(v123);

        expect(!range.allows(new Version.parse('1.2.3')));
        expect(range.allows(new Version.parse('1.3.3')));
        expect(range.allows(new Version.parse('999.3.3')));
      });

      test('allows any version if there is no min or max', () {
        var range = new VersionRange();

        expect(range.allows(new Version.parse('0.0.0')));
        expect(range.allows(new Version.parse('999.99.9')));
      });
    });

    group('intersect()', () {
      test('two overlapping ranges', () {
        var a = new VersionRange(v123, v250);
        var b = new VersionRange(v200, v300);
        var intersect = a.intersect(b);
        expect(intersect.min, equals(v200));
        expect(intersect.max, equals(v250));
        expect(intersect.includeMin, isFalse);
        expect(intersect.includeMax, isFalse);
      });

      test('a non-overlapping range allows no versions', () {
        var a = new VersionRange(v114, v124);
        var b = new VersionRange(v200, v250);
        expect(a.intersect(b).isEmpty);
      });

      test('adjacent ranges allow no versions if exclusive', () {
        var a = new VersionRange(v114, v124, includeMax: false);
        var b = new VersionRange(v124, v200, includeMin: true);
        expect(a.intersect(b).isEmpty);
      });

      test('adjacent ranges allow version if inclusive', () {
        var a = new VersionRange(v114, v124, includeMax: true);
        var b = new VersionRange(v124, v200, includeMin: true);
        expect(a.intersect(b), equals(v124));
      });

      test('with an open range', () {
        var open = new VersionRange();
        var a = new VersionRange(v114, v124);
        expect(open.intersect(open), equals(open));
        expect(a.intersect(open), equals(a));
      });

      test('returns the version if the range allows it', () {
        expect(new VersionRange(v114, v124).intersect(v123), equals(v123));
        expect(new VersionRange(v123, v124).intersect(v114).isEmpty);
      });
    });

    test('isEmpty', () {
      expect(new VersionRange().isEmpty, isFalse);
      expect(new VersionRange(v123, v124).isEmpty, isFalse);
    });
  });

  group('VersionConstraint', () {
    test('empty', () {
      expect(new VersionConstraint.empty().isEmpty);
    });

    group('parse()', () {
      test('parses an exact version', () {
        var constraint = new VersionConstraint.parse('1.2.3-alpha');
        expect(constraint is Version);
        expect(constraint, equals(new Version(1, 2, 3, pre: 'alpha')));
      });

      test('parses "any"', () {
        var constraint = new VersionConstraint.parse('any');
        expect(constraint is VersionConstraint);
        expect(constraint, allows([
            new Version.parse('0.0.0'),
            new Version.parse('1.2.3'),
            new Version.parse('12345.678.90')]));
      });

      test('parses a ">" minimum version', () {
        expect(new VersionConstraint.parse('>1.2.3'), allows([
            new Version.parse('1.2.3+foo'),
            new Version.parse('1.2.4')]));
        expect(new VersionConstraint.parse('>1.2.3'), doesNotAllow([
            new Version.parse('1.2.1'),
            new Version.parse('1.2.3-build'),
            new Version.parse('1.2.3')]));
      });

      test('parses a ">=" minimum version', () {
        expect(new VersionConstraint.parse('>=1.2.3'), allows([
            new Version.parse('1.2.3'),
            new Version.parse('1.2.3+foo'),
            new Version.parse('1.2.4')]));
        expect(new VersionConstraint.parse('>=1.2.3'), doesNotAllow([
            new Version.parse('1.2.1'),
            new Version.parse('1.2.3-build')]));
      });

      test('parses a "<" maximum version', () {
        expect(new VersionConstraint.parse('<1.2.3'), allows([
            new Version.parse('1.2.1'),
            new Version.parse('1.2.3-build')]));
        expect(new VersionConstraint.parse('<1.2.3'), doesNotAllow([
            new Version.parse('1.2.3'),
            new Version.parse('1.2.3+foo'),
            new Version.parse('1.2.4')]));
      });

      test('parses a "<=" maximum version', () {
        expect(new VersionConstraint.parse('<=1.2.3'), allows([
            new Version.parse('1.2.1'),
            new Version.parse('1.2.3-build'),
            new Version.parse('1.2.3')]));
        expect(new VersionConstraint.parse('<=1.2.3'), doesNotAllow([
            new Version.parse('1.2.3+foo'),
            new Version.parse('1.2.4')]));
      });

      test('parses a series of space-separated constraints', () {
        var constraint = new VersionConstraint.parse('>1.0.0 >=1.2.3 <1.3.0');
        expect(constraint, allows([
            new Version.parse('1.2.3'),
            new Version.parse('1.2.5')]));
        expect(constraint, doesNotAllow([
            new Version.parse('1.2.3-pre'),
            new Version.parse('1.3.0'),
            new Version.parse('3.4.5')]));
      });

      test('throws FormatException on a bad string', () {
        expect(() => new VersionConstraint.parse(''), throwsFormatException);
        expect(() => new VersionConstraint.parse('   '), throwsFormatException);
        expect(() => new VersionConstraint.parse('not a version'),
            throwsFormatException);
      });
    });
  });
}

class VersionConstraintMatcher implements Matcher {
  final List<Version> _expected;
  final bool _allow;

  VersionConstraintMatcher(this._expected, this._allow);

  bool matches(item, MatchState matchState) => (item is VersionConstraint) &&
      _expected.every((version) => item.allows(version) == _allow);

  Description describe(Description description) =>
      description.add(' ${_allow ? "allows" : "does not allow"} versions');

  Description describeMismatch(item, Description mismatchDescription,
      MatchState matchState, bool verbose) {
    if (item is! VersionConstraint) {
      mismatchDescription.add('was not a VersionConstraint');
      return mismatchDescription;
    }

    bool first = true;
    for (var version in _expected) {
      if (item.allows(version) != _allow) {
        if (first) {
          if (_allow) {
            mismatchDescription.addDescriptionOf(item).add('did not allow ');
          } else {
            mismatchDescription.addDescriptionOf(item).add('allowed ');
          }
        } else {
          mismatchDescription.add(' and ');
        }
        first = false;

        mismatchDescription.add(version.toString());
      }
    }

    return mismatchDescription;
  }
}

Matcher allows(List<Version> versions) =>
    new VersionConstraintMatcher(versions, true);

Matcher doesNotAllow(List<Version> versions) =>
    new VersionConstraintMatcher(versions, false);

throwsIllegalArg(function) {
  expect(function, throwsA((e) => e is IllegalArgumentException));
}
