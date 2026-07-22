// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/src/utilities/dart_uri.dart';
import 'package:dwds_test_common/fixtures/project.dart';
import 'package:dwds_test_common/fixtures/utilities.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../fixtures/context.dart';

void testAll({
  required TestSdkConfigurationProvider provider,
  required TestContextFactory contextFactory,
}) {
  final testProject = TestProject.test;
  final testPackageProject = TestProject.testPackage();
  final context = contextFactory(testPackageProject, provider);

  group('Debugger module names: true |', () {
    const useDebuggerModuleNames = true;

    final appServerPath = context.usesFrontendServer
        ? 'web/main.dart'
        : 'main.dart';
    final serverPath =
        'packages/${testPackageProject.packageDirectory}/lib/test_library.dart';
    final anotherServerPath =
        'packages/${testProject.packageDirectory}/lib/library.dart';

    setUpAll(() async {
      await context.setUp(
        testSettings: const TestSettings(
          useDebuggerModuleNames: useDebuggerModuleNames,
        ),
      );
    });

    tearDownAll(() async {
      await context.tearDown();
    });

    test('file path to org-dartlang-app', () {
      final webMain = Uri.file(
        p.join(testPackageProject.absolutePackageDirectory, 'web', 'main.dart'),
      );
      final uri = DartUri('$webMain');
      expect(uri.serverPath, appServerPath);
    });

    test('file path to this package', () {
      final testPackageLib = Uri.file(
        p.join(
          testPackageProject.absolutePackageDirectory,
          'lib',
          'test_library.dart',
        ),
      );
      final uri = DartUri('$testPackageLib');
      expect(uri.serverPath, serverPath);
    });

    test('file path to another package', () {
      final testLib = Uri.file(
        p.join(
          testPackageProject.absolutePackageDirectory,
          '..',
          testProject.packageDirectory,
          'lib',
          'library.dart',
        ),
      );
      final dartUri = DartUri('$testLib');
      expect(dartUri.serverPath, anotherServerPath);
    });
  });
}
