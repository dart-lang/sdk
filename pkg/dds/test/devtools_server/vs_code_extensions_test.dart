// Copyright 2023 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils/server_driver.dart';

late final DevToolsServerTestController testController;

void main() {
  testController = DevToolsServerTestController();
  late String emptyDartAppRoot;
  late File extensionConfig;

  setUp(() async {
    await testController.setUp(runPubGet: true);
    emptyDartAppRoot = testController.emptyDartAppRoot.toFilePath();
    extensionConfig = File(path.join(
        testController.packageWithExtensionsRoot.toFilePath(),
        'extension',
        'vs_code',
        'config.yaml'));
    extensionConfig
        .writeAsStringSync('extension: fake-publisher.fake-extension');
  });

  tearDown(() async {
    await testController.tearDown();
  });

  group('Server API - VS Code Extensions', () {
    test('can list valid extensions', () async {
      final results = await testController.send(
        'vscode.extensions.discover',
        {
          'rootPaths': [emptyDartAppRoot]
        },
      );

      expect(
        results,
        {
          emptyDartAppRoot: {
            'extensions': [
              {
                'packageName': 'package_with_extensions',
                'extension': 'fake-publisher.fake-extension'
              },
            ],
            'parseErrors': [],
          },
        },
      );
    }, timeout: const Timeout.factor(10));

    test('returns parse errors for extension/vs_code/config.yaml', () async {
      extensionConfig.writeAsStringSync('a: b');
      final results = await testController.send(
        'vscode.extensions.discover',
        {
          'rootPaths': [emptyDartAppRoot]
        },
      );

      expect(
        results,
        {
          emptyDartAppRoot: {
            'extensions': [],
            'parseErrors': [
              {
                'packageName': 'package_with_extensions',
                'error': 'Bad state: Missing required fields {extension} '
                    'in the extension config.yaml.'
              }
            ]
          },
        },
      );
    });

    test('does not fail on non-existent or non-project folders', () async {
      final notExisting = path.join(emptyDartAppRoot, 'does_not_exist');
      final notProject = path.join(emptyDartAppRoot, 'bin');
      final results = await testController.send(
        'vscode.extensions.discover',
        {
          'rootPaths': [notExisting, notProject]
        },
      );

      expect(
        results,
        {
          notExisting: {
            'extensions': [],
            'parseErrors': [],
          },
          notProject: {
            'extensions': [],
            'parseErrors': [],
          },
        },
      );
    });
  }, timeout: const Timeout.factor(10));
}
