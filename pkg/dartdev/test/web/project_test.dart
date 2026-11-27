// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:dartdev/src/web/project.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

/// Tests that `WebProject.find` finds the package root, package config and
/// entrypoint, and explains what's missing when it can't.
void main() {
  /// A `.dart_tool/package_config.json` that lists [packages]: each package's
  /// name and root directory, relative to the directory with `.dart_tool/`.
  d.DirectoryDescriptor packageConfig(Map<String, String> packages) =>
      d.dir('.dart_tool', [
        d.file(
          'package_config.json',
          jsonEncode({
            'configVersion': 2,
            'packages': [
              for (final MapEntry(key: name, value: root) in packages.entries)
                {'name': name, 'rootUri': '../$root', 'packageUri': 'lib/'},
            ],
          }),
        ),
      ]);

  /// A package named [name] with a package config and [files] in `web/`.
  d.DirectoryDescriptor package(
    String name, {
    List<String> files = const ['main.dart'],
    bool withPackageConfig = true,
  }) => d.dir(name, [
    d.file('pubspec.yaml', 'name: $name'),
    if (withPackageConfig) packageConfig({name: ''}),
    d.dir('web', [for (final file in files) d.file(file, 'void main() {}')]),
  ]);

  String sandbox(String path) => p.normalize(p.join(d.sandbox, path));

  group('finds', () {
    // Each case: the files, the directory and entrypoint to find from, and
    // the expected package root, package config and entrypoint.
    final cases = [
      (
        name: 'web/main.dart by default',
        files: [package('app')],
        directory: 'app',
        entrypoint: null,
        root: 'app',
        packageConfig: 'app/.dart_tool/package_config.json',
        expected: 'web/main.dart',
      ),
      (
        name: 'the package root from a subdirectory',
        files: [package('app')],
        directory: 'app/web',
        entrypoint: null,
        root: 'app',
        packageConfig: 'app/.dart_tool/package_config.json',
        expected: 'web/main.dart',
      ),
      (
        name: 'a given entrypoint',
        files: [
          package('app', files: ['main.dart', 'other.dart']),
        ],
        directory: 'app',
        entrypoint: 'web/other.dart',
        root: 'app',
        packageConfig: 'app/.dart_tool/package_config.json',
        expected: 'web/other.dart',
      ),
      (
        name: 'the workspace package config',
        files: [
          d.dir('workspace', [
            d.file('pubspec.yaml', 'name: workspace'),
            packageConfig({'workspace': '', 'app': 'pkgs/app/'}),
            d.dir('pkgs', [package('app', withPackageConfig: false)]),
          ]),
        ],
        directory: 'workspace/pkgs/app',
        entrypoint: null,
        root: 'workspace/pkgs/app',
        packageConfig: 'workspace/.dart_tool/package_config.json',
        expected: 'web/main.dart',
      ),
    ];
    for (final c in cases) {
      test(c.name, () async {
        for (final file in c.files) {
          await file.create();
        }
        final project = await WebProject.find(
          sandbox(c.directory),
          entrypoint: c.entrypoint,
        );
        expect(project.packageRoot, sandbox(c.root));
        expect(project.packageConfigPath, sandbox(c.packageConfig));
        expect(
          project.packageConfig['app']?.root,
          Uri.directory(sandbox(c.root)),
        );
        expect(project.entrypoint, c.expected);
        expect(project.webDirectory, sandbox('${c.root}/web'));
        expect(project.relativeWebDirectory, 'web');
      });
    }
  });

  group('explains', () {
    // Each case: the files, the entrypoint, and part of the expected message.
    final cases = [
      (
        name: 'a directory outside any package',
        files: [d.dir('app')],
        entrypoint: null,
        message: 'No package found for',
      ),
      (
        name: 'a missing package config',
        files: [package('app', withPackageConfig: false)],
        entrypoint: null,
        message: 'No package found for',
      ),
      (
        name: 'a directory in no package of the nearest package config',
        files: [
          packageConfig({'other': 'other/'}),
          package('app', withPackageConfig: false),
        ],
        entrypoint: null,
        message: "isn't in a package. Run `dart pub get` in your package first",
      ),
      (
        name: 'an invalid package config',
        files: [
          d.dir('app', [
            d.file('pubspec.yaml', 'name: app'),
            d.dir('.dart_tool', [d.file('package_config.json', '{}')]),
            d.dir('web', [d.file('main.dart', 'void main() {}')]),
          ]),
        ],
        entrypoint: null,
        message: 'Could not read',
      ),
      (
        name: 'a missing web/ directory',
        files: [
          d.dir('app', [
            d.file('pubspec.yaml', 'name: app'),
            packageConfig({'app': ''}),
          ]),
        ],
        entrypoint: null,
        message: 'No web/ directory found',
      ),
      (
        name: 'a missing web/main.dart',
        files: [
          package('app', files: ['other.dart']),
        ],
        entrypoint: null,
        message: 'No entrypoint found at web/main.dart',
      ),
      (
        name: 'an entrypoint outside web/',
        files: [package('app')],
        entrypoint: 'lib/main.dart',
        message:
            'must be a Dart file directly in web/, such as web/main.dart, '
            'but got lib/main.dart.',
      ),
      (
        name: 'an entrypoint in a subdirectory of web/',
        files: [package('app')],
        entrypoint: 'web/sub/main.dart',
        message:
            'must be a Dart file directly in web/, such as web/main.dart, '
            'but got web/sub/main.dart.',
      ),
    ];
    for (final c in cases) {
      test(c.name, () async {
        for (final file in c.files) {
          await file.create();
        }
        await expectLater(
          WebProject.find(sandbox('app'), entrypoint: c.entrypoint),
          throwsA(
            isA<ProjectException>().having(
              (e) => e.message,
              'message',
              contains(c.message),
            ),
          ),
        );
      });
    }

    test('a nested package without dart pub get', () async {
      await d.dir('app', [
        d.file('pubspec.yaml', 'name: app'),
        packageConfig({'app': ''}),
        d.dir('web', [d.file('main.dart', 'void main() {}')]),
        package('example', withPackageConfig: false),
      ]).create();
      await expectLater(
        WebProject.find(sandbox('app/example/web')),
        throwsA(
          isA<ProjectException>().having(
            (e) => e.message,
            'message',
            '${sandbox('app/example')} has its own pubspec.yaml. '
                'Run `dart pub get` there first.',
          ),
        ),
      );
    });

    test('the directory without a trailing `/.`', () async {
      await d.dir('app').create();
      await expectLater(
        WebProject.find(p.join(sandbox('app'), '.')),
        throwsA(
          isA<ProjectException>().having(
            (e) => e.message,
            'message',
            contains('found for ${sandbox('app')}. '),
          ),
        ),
      );
    });

    test('a directory that does not exist', () async {
      await package('app').create();
      await expectLater(
        WebProject.find(sandbox('app/missing')),
        throwsA(
          isA<ProjectException>().having(
            (e) => e.message,
            'message',
            'No directory found at ${sandbox('app/missing')}.',
          ),
        ),
      );
    });

    group('an invalid entrypoint with the path it resolved to', () {
      // Each case: the directory to find from, the entrypoint (relative to
      // that directory), and the path in the message (the sandbox only
      // exists while a test runs).
      final cases = [
        (
          name: 'relative to the package root, from a subdirectory',
          directory: 'app/web',
          entrypoint: 'web/main.dart',
          resolved: () => 'web/web/main.dart',
        ),
        (
          name: 'absolute, for an empty entrypoint',
          directory: 'app',
          entrypoint: '',
          resolved: () => sandbox('app'),
        ),
        (
          name: 'absolute, outside the package',
          directory: 'app',
          entrypoint: '../other.dart',
          resolved: () => sandbox('other.dart'),
        ),
      ];
      for (final c in cases) {
        test(c.name, () async {
          await package('app').create();
          await expectLater(
            WebProject.find(sandbox(c.directory), entrypoint: c.entrypoint),
            throwsA(
              isA<ProjectException>().having(
                (e) => e.message,
                'message',
                endsWith('such as web/main.dart, but got ${c.resolved()}.'),
              ),
            ),
          );
        });
      }
    });
  });
}
