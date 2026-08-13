// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dwds/dwds.dart';
import 'package:dwds_test_common/fixtures/project.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final project = TestProject.testPackage();

  group('Package uri mapper with debugger module names: false |', () {
    const useDebuggerModuleNames = false;
    final fileSystem = const LocalFileSystem();

    final packageUri = Uri(
      scheme: 'package',
      path: '${project.packageName}/test_library.dart',
    );

    final serverPath = '/packages/${project.packageName}/test_library.dart';
    final resolvedPath = '${project.packageDirectory}/lib/test_library.dart';

    late final PackageUriMapper packageUriMapper;
    setUpAll(() async {
      await project.setUp();
      await Process.run(Platform.resolvedExecutable, [
        'pub',
        'upgrade',
      ], workingDirectory: project.absolutePackageDirectory);

      final packageConfigFile = Uri.file(
        p.join(
          project.absolutePackageDirectory,
          '.dart_tool',
          'package_config.json',
        ),
      );

      packageUriMapper = await PackageUriMapper.create(
        fileSystem,
        packageConfigFile,
        useDebuggerModuleNames: useDebuggerModuleNames,
      );
    });

    tearDownAll(project.tearDown);

    test('Can convert package urls to server paths', () {
      expect(packageUriMapper.packageUriToServerPath(packageUri), serverPath);
    });

    test('Can convert server paths to file paths', () {
      expect(
        packageUriMapper.serverPathToResolvedUri(serverPath),
        isA<Uri>()
            .having((uri) => uri.scheme, 'scheme', 'file')
            .having((uri) => uri.path, 'path', endsWith(resolvedPath)),
      );
    });
  });
}
