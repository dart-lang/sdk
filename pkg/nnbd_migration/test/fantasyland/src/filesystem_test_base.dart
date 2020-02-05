// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_repo_impl.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_workspace_impl.dart';
import 'package:nnbd_migration/src/utilities/subprocess_launcher.dart';
import 'package:mockito/mockito.dart';

class MockSubprocessLauncher extends Mock implements SubprocessLauncher {}

class FilesystemTestBase with ResourceProviderMixin {
  MockSubprocessLauncher mockLauncher;
  FantasyRepoDependencies fantasyRepoDependencies;
  FantasyWorkspaceDependencies workspaceDependencies;

  setUp() {
    mockLauncher = MockSubprocessLauncher();
    workspaceDependencies = FantasyWorkspaceDependencies(
        resourceProvider: resourceProvider, launcher: mockLauncher);
    fantasyRepoDependencies = FantasyRepoDependencies.fromWorkspaceDependencies(
        workspaceDependencies);
  }
}
