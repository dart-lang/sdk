// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_workspace.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_workspace_impl.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'src/filesystem_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FantasyWorkspaceTest);
    defineReflectiveTests(FantasyWorkspaceIntegrationTest);
  });
}

@reflectiveTest
class FantasyWorkspaceTest extends FilesystemTestBase {
  setUp() async {
    super.setUp();
  }
}

@reflectiveTest
class FantasyWorkspaceIntegrationTest extends FilesystemTestBase {
  FantasyWorkspace workspace;

  setUp() {
    super.setUp();
  }

  /// Verify connection between workspace and buildGitRepoFrom.
  test_fantasyWorkspaceDevDepsImplIntegration() async {
    workspace = await FantasyWorkspaceTopLevelDevDepsImpl.buildFor(
        'test_package',
        ['extra_package_1', 'extra_package_2'],
        convertPath('/fantasyland'),
        workspaceDependencies: workspaceDependencies);
    expect(getFolder('/fantasyland').exists, isTrue);
    for (var n in ['test_package', 'extra_package_1', 'extra_package_2']) {
      String repoPath = convertPath('/fantasyland/_repo/$n');
      verify(mockLauncher.runStreamed(
          'git',
          [
            'remote',
            'add',
            'origin',
            '-t',
            'master',
            'git@github.com:dart-lang/$n.git'
          ],
          workingDirectory: repoPath));
    }
  }
}
