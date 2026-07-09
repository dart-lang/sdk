// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'package:dwds/src/utilities/dart_uri.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'fixtures/context.dart';
import 'fixtures/project.dart';
import 'fixtures/utilities.dart';

// This tests converting file Uris into our internal paths.
//
// These tests are separated out because we need a running isolate in order to
// look up packages.
void main() {
  final provider = TestSdkConfigurationProvider();
  tearDownAll(provider.dispose);

  final testProject = TestProject.test;
  final testPackageProject = TestProject.testPackage();

  final context = TestContext(testPackageProject, provider);

  for (final compilationMode in CompilationMode.values.where(
    (mode) => !mode.usesDdcModulesOnly,
  )) {
    group('$compilationMode |', () {
      for (final useDebuggerModuleNames in [false, true]) {
        group('Debugger module names: $useDebuggerModuleNames |', () {
          final appServerPath = compilationMode.usesFrontendServer
              ? 'web/main.dart'
              : 'main.dart';

          final serverPath =
              compilationMode.usesFrontendServer && useDebuggerModuleNames
              ? 'packages/${testPackageProject.packageDirectory}/lib/test_library.dart'
              : 'packages/${testPackageProject.packageName}/test_library.dart';

          final anotherServerPath =
              compilationMode.usesFrontendServer && useDebuggerModuleNames
              ? 'packages/${testProject.packageDirectory}/lib/library.dart'
              : 'packages/${testProject.packageName}/library.dart';

          setUpAll(() async {
            await context.setUp(
              testSettings: TestSettings(
                compilationMode: compilationMode,
                useDebuggerModuleNames: useDebuggerModuleNames,
              ),
            );
          });

          tearDownAll(() async {
            await context.tearDown();
          });

          test('file path to org-dartlang-app', () {
            final webMain = Uri.file(
              p.join(
                // The directory for the _testPackage package which imports
                // _test.
                testPackageProject.absolutePackageDirectory,
                'web',
                'main.dart',
              ),
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
                // The directory for the general _test package. This is going to
                // be relative to the project in the `TestContext`.
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
    });
  }
}
