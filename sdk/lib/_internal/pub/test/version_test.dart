// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library version_test;

import 'package:unittest/unittest.dart';
import 'test_pub.dart';
import '../lib/src/version.dart';

main() {
  initConfig();

  final v114 = new Version.parse('1.1.4');
  final v123 = new Version.parse('1.2.3');
  final v124 = new Version.parse('1.2.4');
  final v130 = new Version.parse('1.3.0');
  final v140 = new Version.parse('1.4.0');
  final v200 = new Version.parse('2.0.0');
  final v201 = new Version.parse('2.0.1');
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

      test('equality', () {
        expect(new Version.parse('01.2.3'), equals(new Version.parse('1.2.3')));
        expect(new Version.parse('1.02.3'), equals(new Version.parse('1.2.3')));
        expect(new Version.parse('1.2.03'), equals(new Version.parse('1.2.3')));
        expect(new Version.parse('1.2.3-01'),
            equals(new Version.parse('1.2.3-1')));
        expect(new Version.parse('1.2.3+01'),
            equals(new Version.parse('1.2.3+1')));
      });
    });

    test('allows()', () {
      expect(v123.allows(v123), isTrue);
      expect(v123.allows(v114), isFalse);
      expect(v123.allows(v124), isFalse);
    });

    test('intersect()', () {
      // Intersecting the same version returns the version.
      expect(v123.intersect(v123), equals(v123));

      // Intersecting a different version allows no versions.
      expect(v123.intersect(v114).isEmpty, isTrue);

      // Intersecting a range returns the version if the range allows it.
      expect(v123.intersect(new VersionRange(min: v114, max: v124)),
          equals(v123));

      // Intersecting a range allows no versions if the range doesn't allow it.
      expect(v114.intersect(new VersionRange(min: v123, max: v124)).isEmpty,
          isTrue);
    });

    test('isEmpty', () {
      expect(v123.isEmpty, isFalse);
    });

    test('nextMajor', () {
      expect(v123.nextMajor, equals(v200));
      expect(v114.nextMajor, equals(v200));
      expect(v200.nextMajor, equals(v300));

      // Ignores pre-release if not on a major version.
      expect(new Version.parse('1.2.3-dev').nextMajor, equals(v200));

      // Just removes it if on a major version.
      expect(new Version.parse('2.0.0-dev').nextMajor, equals(v200));

      // Strips build suffix.
      expect(new Version.parse('1.2.3+patch').nextMajor, equals(v200));
    });

    test('nextMinor', () {
      expect(v123.nextMinor, equals(v130));
      expect(v130.nextMinor, equals(v140));

      // Ignores pre-release if not on a minor version.
      expect(new Version.parse('1.2.3-dev').nextMinor, equals(v130));

      // Just removes it if on a minor version.
      expect(new Version.parse('1.3.0-dev').nextMinor, equals(v130));

      // Strips build suffix.
      expect(new Version.parse('1.2.3+patch').nextMinor, equals(v130));
    });

    test('nextPatch', () {
      expect(v123.nextPatch, equals(v124));
      expect(v200.nextPatch, equals(v201));

      // Just removes pre-release version if present.
      expect(new Version.parse('1.2.4-dev').nextPatch, equals(v124));

      // Strips build suffix.
      expect(new Version.parse('1.2.3+patch').nextPatch, equals(v124));
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
        var range = new VersionRange(min: v123, max: v124);
        expect(range.isAny, isFalse);
        expect(range.min, equals(v123));
        expect(range.max, equals(v124));
      });

      test('allows omitting max', () {
        var range = new VersionRange(min: v123);
        expect(range.isAny, isFalse);
        expect(range.min, equals(v123));
        expect(range.max, isNull);
      });

      test('allows omitting min and max', () {
        var range = new VersionRange();
        expect(range.isAny, isTrue);
        expect(range.min, isNull);
        expect(range.max, isNull);
      });

      test('takes includeMin', () {
        var range = new VersionRange(min: v123, includeMin: true);
        expect(range.includeMin, isTrue);
      });

      test('includeMin defaults to false if omitted', () {
        var range = new VersionRange(min: v123);
        expect(range.includeMin, isFalse);
      });

      test('takes includeMax', () {
        var range = new VersionRange(max: v123, includeMax: true);
        expect(range.includeMax, isTrue);
      });

      test('includeMax defaults to false if omitted', () {
        var range = new VersionRange(max: v123);
        expect(range.includeMax, isFalse);
      });

      test('throws if min > max', () {
        throwsIllegalArg(() => new VersionRange(min: v124, max: v123));
      });
    });

    group('allows()', () {
      test('version must be greater than min', () {
        var range = new VersionRange(min: v123);

        expect(range.allows(new Version.parse('1.2.2')), isFalse);
        expect(range.allows(new Version.parse('1.2.3')), isFalse);
        expect(range.allows(new Version.parse('1.3.3')), isTrue);
        expect(range.allows(new Version.parse('2.3.3')), isTrue);
      });

      test('version must be min or greater if includeMin', () {
        var range = new VersionRange(min: v123, includeMin: true);

        expect(range.allows(new Version.parse('1.2.2')), isFalse);
        expect(range.allows(new Version.parse('1.2.3')), isTrue);
        expect(range.allows(new Version.parse('1.3.3')), isTrue);
        expect(range.allows(new Version.parse('2.3.3')), isTrue);
      });

      test('pre-release versions of inclusive min are excluded', () {
        var range = new VersionRange(min: v123, includeMin: true);

        expect(range.allows(new Version.parse('1.2.3-dev')), isFalse);
        expect(range.allows(new Version.parse('1.2.4-dev')), isTrue);
      });

      test('version must be less than max', () {
        var range = new VersionRange(max: v234);

        expect(range.allows(new Version.parse('2.3.3')), isTrue);
        expect(range.allows(new Version.parse('2.3.4')), isFalse);
        expect(range.allows(new Version.parse('2.4.3')), isFalse);
      });

      test('pre-release versions of non-pre-release max are excluded', () {
        var range = new VersionRange(max: v234);

        expect(range.allows(new Version.parse('2.3.3')), isTrue);
        expect(range.allows(new Version.parse('2.3.4-dev')), isFalse);
        expect(range.allows(new Version.parse('2.3.4')), isFalse);
      });

      test('pre-release versions of pre-release max are included', () {
        var range = new VersionRange(max: new Version.parse('2.3.4-dev.2'));

        expect(range.allows(new Version.parse('2.3.4-dev.1')), isTrue);
        expect(range.allows(new Version.parse('2.3.4-dev.2')), isFalse);
        expect(range.allows(new Version.parse('2.3.4-dev.3')), isFalse);
      });

      test('version must be max or less if includeMax', () {
        var range = new VersionRange(min: v123, max: v234, includeMax: true);

        expect(range.allows(new Version.parse('2.3.3')), isTrue);
        expect(range.allows(new Version.parse('2.3.4')), isTrue);
        expect(range.allows(new Version.parse('2.4.3')), isFalse);

        // Pre-releases of the max are allowed.
        expect(range.allows(new Version.parse('2.3.4-dev')), isTrue);
      });

      test('has no min if one was not set', () {
        var range = new VersionRange(max: v123);

        expect(range.allows(new Version.parse('0.0.0')), isTrue);
        expect(range.allows(new Version.parse('1.2.3')), isFalse);
      });

      test('has no max if one was not set', () {
        var range = new VersionRange(min: v123);

        expect(range.allows(new Version.parse('1.2.3')), isFalse);
        expect(range.allows(new Version.parse('1.3.3')), isTrue);
        expect(range.allows(new Version.parse('999.3.3')), isTrue);
      });

      test('allows any version if there is no min or max', () {
        var range = new VersionRange();

        expect(range.allows(new Version.parse('0.0.0')), isTrue);
        expect(range.allows(new Version.parse('999.99.9')), isTrue);
      });
    });

    group('intersect()', () {
      test('two overlapping ranges', () {
        var a = new VersionRange(min: v123, max: v250);
        var b = new VersionRange(min: v200, max: v300);
        var intersect = a.intersect(b);
        expect(intersect.min, equals(v200));
        expect(intersect.max, equals(v250));
        expect(intersect.includeMin, isFalse);
        expect(intersect.includeMax, isFalse);
      });

      test('a non-overlapping range allows no versions', () {
        var a = new VersionRange(min: v114, max: v124);
        var b = new VersionRange(min: v200, max: v250);
        expect(a.intersect(b).isEmpty, isTrue);
      });

      test('adjacent ranges allow no versions if exclusive', () {
        var a = new VersionRange(min: v114, max: v124, includeMax: false);
        var b = new VersionRange(min: v124, max: v200, includeMin: true);
        expect(a.intersect(b).isEmpty, isTrue);
      });

      test('adjacent ranges allow version if inclusive', () {
        var a = new VersionRange(min: v114, max: v124, includeMax: true);
        var b = new VersionRange(min: v124, max: v200, includeMin: true);
        expect(a.intersect(b), equals(v124));
      });

      test('with an open range', () {
        var open = new VersionRange();
        var a = new VersionRange(min: v114, max: v124);
        expect(open.intersect(open), equals(open));
        expect(a.intersect(open), equals(a));
      });

      test('returns the version if the range allows it', () {
        expect(new VersionRange(min: v114, max: v124).intersect(v123),
            equals(v123));
        expect(new VersionRange(min: v123, max: v124).intersect(v114).isEmpty,
            isTrue);
      });
    });

    test('isEmpty', () {
      expect(new VersionRange().isEmpty, isFalse);
      expect(new VersionRange(min: v123, max: v124).isEmpty, isFalse);
    });
  });

  group('VersionConstraint', () {
    test('any', () {
      expect(VersionConstraint.any.isAny, isTrue);
      expect(VersionConstraint.any, allows([
        new Version.parse('0.0.0-blah'),
        new Version.parse('1.2.3'),
        new Version.parse('12345.678.90')]));
    });

    test('empty', () {
      expect(VersionConstraint.empty.isEmpty, isTrue);
      expect(VersionConstraint.empty.isAny, isFalse);
      expect(VersionConstraint.empty, doesNotAllow([
        new Version.parse('0.0.0-blah'),
        new Version.parse('1.2.3'),
        new Version.parse('12345.678.90')]));
    });

    group('parse()', () {
      test('parses an exact version', () {
        var constraint = new VersionConstraint.parse('1.2.3-alpha');
        expect(constraint is Version, isTrue);
        expect(constraint, equals(new Version(1, 2, 3, pre: 'alpha')));
      });

      test('parses "any"', () {
        var constraint = new VersionConstraint.parse('any');
        expect(constraint is VersionConstraint, isTrue);
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
            new Version.parse('1.2.2+foo')]));
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

      test('ignores whitespace around operators', () {
        var constraint = new VersionConstraint.parse(' >1.0.0>=1.2.3 < 1.3.0');
        expect(constraint, allows([
            new Version.parse('1.2.3'),
            new Version.parse('1.2.5')]));
        expect(constraint, doesNotAllow([
            new Version.parse('1.2.3-pre'),
            new Version.parse('1.3.0'),
            new Version.parse('3.4.5')]));
      });

      test('does not allow "any" to be mixed with other constraints', () {
        expect(() => new VersionConstraint.parse('any 1.0.0'),
            throwsFormatException);
      });

      test('throws FormatException on a bad string', () {
        var bad = [
           "", "   ",               // Empty string.
           "foo",                   // Bad text.
           ">foo",                  // Bad text after operator.
           "1.0.0 foo", "1.0.0foo", // Bad text after version.
           "anything",              // Bad text after "any".
           "<>1.0.0",               // Multiple operators.
           "1.0.0<"                 // Trailing operator.
        ];

        for (var text in bad) {
          expect(() => new VersionConstraint.parse(text),
              throwsFormatException);
        }
      });
    });
  });
}

class VersionConstraintMatcher implements Matcher {
  final List<Version> _expected;
  final bool _allow;

  VersionConstraintMatcher(this._expected, this._allow);

  bool matches(item, Map matchState) => (item is VersionConstraint) &&
      _expected.every((version) => item.allows(version) == _allow);

  Description describe(Description description) =>
      description.add(' ${_allow ? "allows" : "does not allow"} versions');

  Description describeMismatch(item, Description mismatchDescription,
      Map matchState, bool verbose) {
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
  expect(function, throwsA((e) => e is ArgumentError));
}
