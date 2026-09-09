// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
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

    test('missing mode flag (--apply or --dry-run)', () async {
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
      expect(
        result.stderr,
        allOf(
          contains("Directory or file doesn't exist:"),
          contains('nonexistent'),
        ),
      );
    });

    test('multiple invalid targets', () async {
      p = project(mainSrc: 'class Foo {}\n');

      final result = await p.runMigrate([
        '--dry-run',
        '${p.dirPath}_nonexistent1',
        '${p.dirPath}_nonexistent2',
      ]);

      expect(result.exitCode, isNot(0));
      expect(
        result.stderr,
        allOf(
          contains("Directory or file doesn't exist:"),
          contains('nonexistent1'),
          contains('nonexistent2'),
        ),
      );
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

    test('multiple targets', () async {
      p = project(mainSrc: 'class Foo {}\n');
      final p2 = project(name: 'dartdev_temp2', mainSrc: 'class Bar {}\n');

      final result = await p.runMigrate(['--apply', p.dirPath, p2.dirPath]);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(result.stdout, contains('Migrating 2 packages'));
    });

    test('duplicate targets are deduplicated', () async {
      p = project(mainSrc: 'class Foo {}\n');

      final result = await p.runMigrate(['--apply', p.dirPath, p.dirPath]);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(result.stdout, contains('Migrating package '));
    });

    test('symlinked duplicate targets are deduplicated', () async {
      p = project(mainSrc: 'class Foo {}\n');
      final symlinkPath = path.join(p.root.path, 'myapp_link');
      Link(symlinkPath).createSync(p.dirPath);

      final result = await p.runMigrate(['--apply', p.dirPath, symlinkPath]);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(result.stdout, contains('Migrating package '));
    });

    test('default current directory', () async {
      p = project(
        mainSrc: 'class Foo {}\n',
        sdkConstraint: VersionConstraint.parse('^3.11.0'),
      );

      final result = await p.runMigrate(['--apply']);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final pubspec = File(
        path.join(p.dirPath, 'pubspec.yaml'),
      ).readAsStringSync();
      expect(pubspec, contains('^3.12.0'));
    });

    test('--dry-run with --target-sdk prints apply tip', () async {
      p = project(
        mainSrc: 'class Foo {}\n',
        sdkConstraint: VersionConstraint.parse('^3.11.0'),
      );

      var result = await p.runMigrate([
        '--dry-run',
        '--target-sdk=3.13.0',
        p.dirPath,
      ]);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(
        result.stdout,
        contains(
          'To apply the proposed changes, run:\n'
          '  dart migrate --apply --target-sdk=3.13.0 ${p.dirPath}',
        ),
      );
    });

    test('--apply --target-sdk', () async {
      p = project(
        mainSrc: 'class Foo {}\n',
        sdkConstraint: VersionConstraint.parse('^3.11.0'),
      );

      final result = await p.runMigrate([
        '--apply',
        '--target-sdk=3.13.0',
        p.dirPath,
      ]);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final pubspec = File(
        path.join(p.dirPath, 'pubspec.yaml'),
      ).readAsStringSync();
      expect(pubspec, contains('^3.13.0'));
    });
  });
}
