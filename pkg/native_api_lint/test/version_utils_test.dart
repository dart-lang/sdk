// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:native_api_lint/src/version_utils.dart';

void main() {
  group('compareVersions', () {
    test('equal versions', () {
      expect(compareVersions('14.0', '14.0'), 0);
      expect(compareVersions('11', '11'), 0);
      expect(compareVersions('14.2.1', '14.2.1'), 0);
    });

    test('major version difference', () {
      expect(compareVersions('14.0', '13.0'), isPositive);
      expect(compareVersions('13.0', '14.0'), isNegative);
    });

    test('minor version difference', () {
      expect(compareVersions('14.1', '14.0'), isPositive);
      expect(compareVersions('14.0', '14.1'), isNegative);
    });

    test('missing minor component treated as zero', () {
      expect(compareVersions('14', '14.0'), 0);
      expect(compareVersions('14.1', '14'), isPositive);
    });

    test('three-component versions', () {
      expect(compareVersions('14.2.1', '14.2.0'), isPositive);
      expect(compareVersions('14.2.0', '14.2.1'), isNegative);
    });
  });

  group('apiRequiresNewerThan', () {
    test('api requires newer OS — returns true', () {
      expect(apiRequiresNewerThan('14.0', '13.0'), isTrue);
    });

    test('api matches project min — returns false', () {
      expect(apiRequiresNewerThan('14.0', '14.0'), isFalse);
    });

    test('api is older than project min — returns false', () {
      expect(apiRequiresNewerThan('12.0', '14.0'), isFalse);
    });
  });

  group('apiObsoletedBefore', () {
    test('api removed before project min — returns true (crash risk)', () {
      expect(apiObsoletedBefore('12.0', '14.0'), isTrue);
    });

    test('api removed exactly at project min — returns true', () {
      expect(apiObsoletedBefore('14.0', '14.0'), isTrue);
    });

    test('api removed after project min — returns false (still available)', () {
      expect(apiObsoletedBefore('16.0', '14.0'), isFalse);
    });
  });

  group('apiDeprecatedOn', () {
    test('project min is in deprecated window — returns true', () {
      // deprecated at 12.0, obsoleted at 16.0, project targets 14.0
      expect(apiDeprecatedOn('12.0', '16.0', '14.0'), isTrue);
    });

    test('project min is exactly at deprecation point — returns true', () {
      expect(apiDeprecatedOn('14.0', '16.0', '14.0'), isTrue);
    });

    test('project min is before deprecation — returns false', () {
      expect(apiDeprecatedOn('14.0', '16.0', '13.0'), isFalse);
    });

    test('project min is at or past obsoleted — returns false', () {
      expect(apiDeprecatedOn('12.0', '16.0', '16.0'), isFalse);
      expect(apiDeprecatedOn('12.0', '16.0', '17.0'), isFalse);
    });

    test('no obsoleted version (still deprecated, not removed) — returns true', () {
      expect(apiDeprecatedOn('12.0', null, '14.0'), isTrue);
    });

    test('no obsoleted version, project before deprecation — returns false', () {
      expect(apiDeprecatedOn('14.0', null, '13.0'), isFalse);
    });
  });
}
