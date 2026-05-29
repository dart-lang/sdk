// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package.dart';

void main() {
  group('Package', () {
    test('creates package from file map', () async {
      final pkg = await Package.fromFileMap({
        'pubspec.yaml': 'name: mypkg\nversion: 1.2.3',
        'lib/mypkg.dart': 'void main() {}',
      });

      expect(pkg.name, 'mypkg');
      expect(pkg.version.toString(), '1.2.3');
      expect(pkg.archive, isNotEmpty);
    });

    test('throws if pubspec is missing', () async {
      expect(
        () => Package.fromFileMap({'lib/mypkg.dart': 'void main() {}'}),
        throwsFormatException,
      );
    });

    test('throws if name is missing from pubspec', () async {
      expect(
        () => Package.fromFileMap({'pubspec.yaml': 'version: 1.2.3'}),
        throwsFormatException,
      );
    });

    test('throws if version is missing from pubspec', () async {
      expect(
        () => Package.fromFileMap({'pubspec.yaml': 'name: mypkg'}),
        throwsFormatException,
      );
    });
  });
}
