// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('migrate', migrate, timeout: longTimeout);
}

void migrate() {
  late TestProject p;

  group('usage', () {
    test('--help', () async {
      p = project(mainSrc: 'class Foo {}\n');

      final result = await p.runMigrate(['--help']);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(
        result.stdout,
        contains('Migrate Dart packages to newer SDK versions.'),
      );
      expect(result.stdout, contains('Usage: dart migrate [arguments]'));
    });

    test('no args', () async {
      p = project(mainSrc: 'class Foo {}\n');

      final result = await p.runMigrate([p.dirPath]);

      expect(result.exitCode, isNot(0));
      expect(
        result.stderr,
        contains('Must specify either --apply or --dry-run.'),
      );
    });

    test('both --apply and --dry-run', () async {
      p = project(mainSrc: 'class Foo {}\n');

      final result = await p.runMigrate(['--apply', '--dry-run', p.dirPath]);

      expect(result.exitCode, isNot(0));
      expect(
        result.stderr,
        contains(
          'Cannot specify both --apply and --dry-run. Please specify one.',
        ),
      );
    });

    test('invalid target', () async {
      p = project(mainSrc: 'class Foo {}\n');

      final result = await p.runMigrate([
        '--dry-run',
        '${p.dirPath}_nonexistent',
      ]);

      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains("File doesn't exist:"));
    });
  });

  group('perform', () {
    test('--dry-run', () async {
      p = project(mainSrc: 'class Foo {}\n');

      final result = await p.runMigrate(['--dry-run', p.dirPath]);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
    });

    test('--dry-run with changes prints apply tip', () async {
      p = project(
        mainSrc: 'class Foo {}\n',
        sdkConstraint: VersionConstraint.parse('^3.12.0'),
      );

      var result = await p.runMigrate(['--dry-run', '--step=bump', p.dirPath]);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(
        result.stdout,
        contains(
          'To apply the proposed changes, run:\n'
          '  dart migrate --apply --step=bump ${p.dirPath}',
        ),
      );
    });

    test('--apply', () async {
      p = project(mainSrc: 'class Foo {}\n');

      final result = await p.runMigrate(['--apply', p.dirPath]);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
    });

    test('--apply --step=bump', () async {
      p = project(mainSrc: 'class Foo {}\n');

      final result = await p.runMigrate(['--apply', '--step=bump', p.dirPath]);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
    });

    test('--apply --step=prepare,bump', () async {
      p = project(mainSrc: 'class Foo {}\n');

      final result = await p.runMigrate([
        '--apply',
        '--step=prepare,bump',
        p.dirPath,
      ]);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
    });
  });
}
